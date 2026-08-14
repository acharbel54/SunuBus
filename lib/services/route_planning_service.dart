import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../data/datasources/dakar_network.dart';
import '../data/datasources/multimodal_network.dart';
import '../data/models/bus_line.dart';
import '../data/models/bus_stop.dart';
import '../data/models/itinerary.dart';
import '../data/models/itinerary_leg.dart';
import '../data/models/transport_mode.dart';
import '../data/models/trip_preferences.dart';

/// Contrat de recherche d'itinéraire multimodal. `MockRoutePlanningService`
/// est l'implémentation actuelle (calcul local, sans réseau) ; en
/// production, cette interface serait implémentée par un client HTTP vers
/// un vrai moteur d'itinéraires (ex: OpenTripPlanner, GTFS-RT, Google
/// Directions API), sans que le reste de l'app n'ait à changer.
abstract class RoutePlanningApi {
  Future<List<Itinerary>> search({
    required LatLng origin,
    required String originLabel,
    required LatLng destination,
    required String destinationLabel,
    required TripPreferences preferences,
    DateTime? departAt,
  });
}

/// Génère des itinéraires plausibles en combinant marche + le mode motorisé
/// le plus adapté (bus/tram/navette : la ligne dont les arrêts minimisent la
/// marche ; taxi : trajet direct porte-à-porte).
class MockRoutePlanningService implements RoutePlanningApi {
  MockRoutePlanningService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Horloge injectable : les tests peuvent fixer l'heure "maintenant" au
  /// lieu de dépendre de l'horloge système (déterminisme).
  final DateTime Function() _now;

  @override
  Future<List<Itinerary>> search({
    required LatLng origin,
    required String originLabel,
    required LatLng destination,
    required String destinationLabel,
    required TripPreferences preferences,
    DateTime? departAt,
  }) async {
    // Latence simulée, pour un retour utilisateur cohérent avec un vrai appel réseau.
    await Future.delayed(const Duration(milliseconds: 450));

    final departureTime = departAt ?? _now();
    final itineraries = <Itinerary>[];

    // Niveau de confort minimal exigé par l'utilisateur (1 à 5) : les modes
    // dont le score est inférieur sont écartés de la recherche.
    final minComfortScore = _minComfortScore(preferences.comfortLevel);

    if (preferences.preferredModes.contains(TransportMode.bus)) {
      final it = _buildLineItinerary(
        mode: TransportMode.bus,
        lines: DakarNetwork.lines,
        origin: origin,
        originLabel: originLabel,
        destination: destination,
        destinationLabel: destinationLabel,
        departureTime: departureTime,
        comfortScore: 2,
        minComfortScore: minComfortScore,
        maxWalkMinutes: preferences.maxWalkMinutes,
      );
      if (it != null) itineraries.add(it);
    }

    if (preferences.preferredModes.contains(TransportMode.tram)) {
      final it = _buildLineItinerary(
        mode: TransportMode.tram,
        lines: MultimodalNetwork.tramLines,
        origin: origin,
        originLabel: originLabel,
        destination: destination,
        destinationLabel: destinationLabel,
        departureTime: departureTime,
        comfortScore: 4,
        minComfortScore: minComfortScore,
        maxWalkMinutes: preferences.maxWalkMinutes,
      );
      if (it != null) itineraries.add(it);
    }

    if (preferences.preferredModes.contains(TransportMode.navette)) {
      final it = _buildLineItinerary(
        mode: TransportMode.navette,
        lines: MultimodalNetwork.navetteLines,
        origin: origin,
        originLabel: originLabel,
        destination: destination,
        destinationLabel: destinationLabel,
        departureTime: departureTime,
        comfortScore: 3,
        minComfortScore: minComfortScore,
        maxWalkMinutes: preferences.maxWalkMinutes,
      );
      if (it != null) itineraries.add(it);
    }

    if (preferences.preferredModes.contains(TransportMode.taxi)) {
      itineraries.add(_buildDirectTaxi(
        origin: origin,
        originLabel: originLabel,
        destination: destination,
        destinationLabel: destinationLabel,
        departureTime: departureTime,
      ));
    }

    // Garantit au moins un résultat (trajet direct en taxi) même si aucune
    // ligne n'est pertinente pour les modes sélectionnés — sauf si
    // l'utilisateur a explicitement exclu le taxi de ses préférences, auquel
    // cas on respecte ce choix plutôt que de le lui imposer en secours.
    if (itineraries.isEmpty && preferences.preferredModes.contains(TransportMode.taxi)) {
      itineraries.add(_buildDirectTaxi(
        origin: origin,
        originLabel: originLabel,
        destination: destination,
        destinationLabel: destinationLabel,
        departureTime: departureTime,
      ));
    }

    return itineraries;
  }

  Itinerary _buildDirectTaxi({
    required LatLng origin,
    required String originLabel,
    required LatLng destination,
    required String destinationLabel,
    required DateTime departureTime,
  }) {
    final distance = MultimodalNetwork.distanceKm(origin, destination);
    final duration = MultimodalNetwork.estimatedDurationMinutes(TransportMode.taxi, distance);
    final price = MultimodalNetwork.estimatedPriceFcfa(TransportMode.taxi, distance);

    final leg = ItineraryLeg(
      mode: TransportMode.taxi,
      fromLabel: originLabel,
      toLabel: destinationLabel,
      durationMinutes: duration,
      priceFcfa: price,
      points: [origin, destination],
    );

    return Itinerary(
      id: 'taxi-${departureTime.millisecondsSinceEpoch}',
      legs: [leg],
      departureTime: departureTime,
      arrivalTime: departureTime.add(Duration(minutes: duration)),
      totalDurationMinutes: duration,
      totalPriceFcfa: price,
      comfortScore: 5,
    );
  }

  /// Choisit, parmi [lines], celle dont les arrêts minimisent la distance de
  /// marche totale (origine -> arrêt de départ) + (arrêt d'arrivée ->
  /// destination), puis construit un itinéraire marche + [mode] + marche.
  /// Retourne `null` si [lines] est vide ou si l'arrêt le plus proche de
  /// l'origine et celui le plus proche de la destination sont identiques
  /// (aucun trajet motorisé pertinent).
  Itinerary? _buildLineItinerary({
    required TransportMode mode,
    required List<BusLine> lines,
    required LatLng origin,
    required String originLabel,
    required LatLng destination,
    required String destinationLabel,
    required DateTime departureTime,
    required int comfortScore,
    required int minComfortScore,
    required int maxWalkMinutes,
  }) {
    if (lines.isEmpty) return null;
    // Contrainte de confort : mode en dessous du niveau demandé -> écarté.
    if (comfortScore < minComfortScore) return null;

    // Distance de marche maximale tolérée (km), dérivée du budget en minutes
    // de l'utilisateur (vitesse de marche moyenne).
    final maxWalkKm = maxWalkMinutes * TransportMode.walk.averageSpeedKmh / 60.0;

    BusLine? bestLine;
    BusStop? bestOriginStop;
    BusStop? bestDestStop;
    double bestCost = double.infinity;

    for (final line in lines) {
      final originNearest = MultimodalNetwork.nearest(origin, line.stops);
      final destNearest = MultimodalNetwork.nearest(destination, line.stops);

      // Contrainte de marche max : la ligne n'est candidate que si la marche
      // totale (aller + retour) reste dans le budget de l'utilisateur.
      final cost = originNearest.value + destNearest.value;
      if (cost > maxWalkKm) continue;

      if (cost < bestCost) {
        bestCost = cost;
        bestLine = line;
        bestOriginStop = originNearest.key;
        bestDestStop = destNearest.key;
      }
    }

    if (bestLine == null || bestOriginStop!.id == bestDestStop!.id) return null;

    final legs = <ItineraryLeg>[];

    final walkToStopKm = MultimodalNetwork.distanceKm(origin, bestOriginStop.position);
    if (walkToStopKm > 0.05) {
      legs.add(ItineraryLeg(
        mode: TransportMode.walk,
        fromLabel: originLabel,
        toLabel: bestOriginStop.name,
        durationMinutes: MultimodalNetwork.estimatedDurationMinutes(TransportMode.walk, walkToStopKm),
        priceFcfa: 0,
        points: [origin, bestOriginStop.position],
      ));
    }

    final transitDistanceKm = MultimodalNetwork.distanceKm(bestOriginStop.position, bestDestStop.position);
    legs.add(ItineraryLeg(
      mode: mode,
      fromLabel: bestOriginStop.name,
      toLabel: bestDestStop.name,
      lineId: bestLine.id,
      durationMinutes: MultimodalNetwork.estimatedDurationMinutes(mode, transitDistanceKm),
      priceFcfa: MultimodalNetwork.estimatedPriceFcfa(mode, transitDistanceKm),
      points: _subPolyline(bestLine, bestOriginStop, bestDestStop),
    ));

    final walkFromStopKm = MultimodalNetwork.distanceKm(bestDestStop.position, destination);
    if (walkFromStopKm > 0.05) {
      legs.add(ItineraryLeg(
        mode: TransportMode.walk,
        fromLabel: bestDestStop.name,
        toLabel: destinationLabel,
        durationMinutes: MultimodalNetwork.estimatedDurationMinutes(TransportMode.walk, walkFromStopKm),
        priceFcfa: 0,
        points: [bestDestStop.position, destination],
      ));
    }

    final totalDuration = legs.fold<int>(0, (sum, leg) => sum + leg.durationMinutes);
    final totalPrice = legs.fold<double>(0, (sum, leg) => sum + leg.priceFcfa);

    return Itinerary(
      id: '${mode.name}-${bestLine.id}-${departureTime.millisecondsSinceEpoch}',
      legs: legs,
      departureTime: departureTime,
      arrivalTime: departureTime.add(Duration(minutes: totalDuration)),
      totalDurationMinutes: totalDuration,
      totalPriceFcfa: totalPrice,
      comfortScore: comfortScore,
    );
  }

  /// Score de confort minimal (1 à 5) requis par chaque niveau de préférence.
  /// `economique` accepte tout, `standard` exige un minimum de confort,
  /// `confort` n'autorise que les modes les plus confortables (ex: TER, taxi).
  static int _minComfortScore(ComfortLevel level) {
    switch (level) {
      case ComfortLevel.economique:
        return 1;
      case ComfortLevel.standard:
        return 2;
      case ComfortLevel.confort:
        return 4;
    }
  }

  List<LatLng> _subPolyline(BusLine line, BusStop from, BusStop to) {
    final fromIdx = line.stops.indexWhere((s) => s.id == from.id);
    final toIdx = line.stops.indexWhere((s) => s.id == to.id);
    if (fromIdx == -1 || toIdx == -1) return [from.position, to.position];

    final start = min(fromIdx, toIdx);
    final end = max(fromIdx, toIdx);
    final slice = line.stops.sublist(start, end + 1).map((s) => s.position).toList();
    return fromIdx <= toIdx ? slice : slice.reversed.toList();
  }
}
