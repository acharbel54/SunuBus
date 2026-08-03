import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import 'dakar_network.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/transport_mode.dart';

/// Complète `DakarNetwork` (non modifié, pour ne pas risquer de perturber la
/// simulation bus existante) avec les autres modes de transport de la
/// recherche multimodale : stations de taxi, lignes de navette, et une
/// ligne "tram" (express, type TER) reliant Dakar à sa proche banlieue.
///
/// Comme le reste de l'app, ces données sont un jeu de données fictif mais
/// géographiquement plausible : il n'y a pas de connexion à un vrai fournisseur
/// de données de transport.
class MultimodalNetwork {
  MultimodalNetwork._();

  static const List<BusStop> taxiStations = [
    BusStop(id: 'taxi-plateau', name: 'Station taxi — Plateau', position: LatLng(14.6698, -17.4374)),
    BusStop(id: 'taxi-almadies', name: 'Station taxi — Almadies', position: LatLng(14.7442, -17.5133)),
    BusStop(id: 'taxi-ouakam', name: 'Station taxi — Ouakam', position: LatLng(14.7190, -17.4870)),
    BusStop(id: 'taxi-medina', name: 'Station taxi — Médina', position: LatLng(14.6801, -17.4448)),
    BusStop(id: 'taxi-aeroport', name: 'Station taxi — Aéroport (Yoff)', position: LatLng(14.7397, -17.4903)),
    BusStop(id: 'taxi-parcelles', name: 'Station taxi — Parcelles Assainies', position: LatLng(14.7654, -17.4270)),
  ];

  static const BusLine navetteAeroport = BusLine(
    id: 'navette-aeroport',
    number: 'Navette Aéroport',
    operatorName: 'AIBD',
    color: AppColors.ocreSable,
    stops: [
      BusStop(id: 'nav-plateau', name: 'Plateau', position: LatLng(14.6714, -17.4383)),
      BusStop(id: 'nav-patte-oie', name: 'Patte d\'Oie', position: LatLng(14.7269, -17.4530)),
      BusStop(id: 'nav-diamniadio', name: 'Diamniadio', position: LatLng(14.7264, -17.1875)),
      BusStop(id: 'nav-aibd', name: 'Aéroport AIBD', position: LatLng(14.6708, -17.0733)),
    ],
  );

  static const BusLine navetteUniversite = BusLine(
    id: 'navette-ucad',
    number: 'Navette Université',
    operatorName: 'UCAD',
    color: AppColors.rouilleAlerte,
    stops: [
      BusStop(id: 'nav-fann', name: 'Fann', position: LatLng(14.6928, -17.4645)),
      BusStop(id: 'nav-point-e', name: 'Point E', position: LatLng(14.6928, -17.4550)),
      BusStop(id: 'nav-medina-2', name: 'Médina', position: LatLng(14.6801, -17.4448)),
      BusStop(id: 'nav-plateau-2', name: 'Plateau', position: LatLng(14.6714, -17.4383)),
    ],
  );

  /// Ligne "tram" : express type TER (Train Express Régional) reliant le
  /// centre-ville à Diamniadio.
  static const BusLine terExpress = BusLine(
    id: 'ter-express',
    number: 'TER',
    operatorName: 'SETER',
    color: AppColors.bleuAtlantique,
    stops: [
      BusStop(id: 'ter-dakar', name: 'Gare de Dakar', position: LatLng(14.6742, -17.4302)),
      BusStop(id: 'ter-hann', name: 'Hann', position: LatLng(14.7139, -17.4392)),
      BusStop(id: 'ter-pikine-2', name: 'Pikine', position: LatLng(14.7547, -17.3900)),
      BusStop(id: 'ter-diamniadio-2', name: 'Diamniadio', position: LatLng(14.7264, -17.1875)),
    ],
  );

  static const List<BusLine> navetteLines = [navetteAeroport, navetteUniversite];
  static const List<BusLine> tramLines = [terExpress];

  /// Tous les lieux connus du réseau (arrêts de bus, stations de taxi,
  /// arrêts de navette/tram), dédupliqués par nom — utilisé pour
  /// l'autocomplétion de la recherche d'itinéraire.
  static List<BusStop> get allKnownLocations {
    final Map<String, BusStop> byName = {};
    for (final stop in DakarNetwork.allStops) {
      byName[stop.name] = stop;
    }
    for (final stop in taxiStations) {
      byName[stop.name] = stop;
    }
    for (final line in [...navetteLines, ...tramLines]) {
      for (final stop in line.stops) {
        byName[stop.name] = stop;
      }
    }
    return byName.values.toList();
  }

  static BusLine lineForMode(TransportMode mode, String lineId) {
    final all = [...navetteLines, ...tramLines];
    return all.firstWhere((l) => l.id == lineId);
  }

  static const Distance _distanceCalculator = Distance();

  static double distanceKm(LatLng a, LatLng b) =>
      _distanceCalculator.as(LengthUnit.Kilometer, a, b);

  /// Prix simulé (FCFA) d'un tronçon parcouru en [mode] sur [distanceKm].
  static double estimatedPriceFcfa(TransportMode mode, double distanceKm) {
    return mode.baseFareFcfa + mode.farePerKmFcfa * distanceKm;
  }

  /// Durée simulée (minutes) d'un tronçon parcouru en [mode] sur [distanceKm].
  static int estimatedDurationMinutes(TransportMode mode, double distanceKm) {
    if (distanceKm <= 0) return 1;
    return max(1, (distanceKm / mode.averageSpeedKmh * 60).round());
  }

  /// Le plus proche parmi une liste de points, avec sa distance en km.
  static MapEntry<BusStop, double> nearest(LatLng from, List<BusStop> stops) {
    BusStop best = stops.first;
    double bestDistance = distanceKm(from, best.position);
    for (final stop in stops.skip(1)) {
      final d = distanceKm(from, stop.position);
      if (d < bestDistance) {
        best = stop;
        bestDistance = d;
      }
    }
    return MapEntry(best, bestDistance);
  }
}
