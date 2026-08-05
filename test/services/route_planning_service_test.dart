import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sunu_bus/data/models/transport_mode.dart';
import 'package:sunu_bus/data/models/trip_preferences.dart';
import 'package:sunu_bus/services/route_planning_service.dart';

void main() {
  final service = MockRoutePlanningService();

  // Plateau -> Guédiawaye : deux points réels du réseau simulé, assez
  // éloignés pour que bus/taxi/navette donnent des itinéraires distincts.
  const origin = LatLng(14.6714, -17.4383);
  const destination = LatLng(14.7730, -17.4090);

  test('propose un itinéraire par mode de transport autorisé', () async {
    final results = await service.search(
      origin: origin,
      originLabel: 'Plateau',
      destination: destination,
      destinationLabel: 'Guédiawaye',
      preferences: TripPreferences.defaults,
    );

    expect(results, isNotEmpty);
    for (final itinerary in results) {
      expect(itinerary.legs, isNotEmpty);
      expect(itinerary.totalDurationMinutes, greaterThan(0));
      expect(itinerary.totalPriceFcfa, greaterThanOrEqualTo(0));
      expect(itinerary.arrivalTime.isAfter(itinerary.departureTime), isTrue);
    }
  });

  test('respecte le filtre de modes des préférences', () async {
    final results = await service.search(
      origin: origin,
      originLabel: 'Plateau',
      destination: destination,
      destinationLabel: 'Guédiawaye',
      preferences: const TripPreferences(
        preferredModes: {TransportMode.taxi},
        comfortLevel: ComfortLevel.confort,
        maxWalkMinutes: 10,
      ),
    );

    expect(results, isNotEmpty);
    for (final itinerary in results) {
      expect(itinerary.primaryModes, everyElement(TransportMode.taxi));
    }
  });

  test('un trajet direct en taxi est toujours proposé en secours', () async {
    // Aucune ligne bus/tram/navette ne dessert forcément ces deux points,
    // mais le service doit toujours renvoyer au moins un itinéraire.
    final results = await service.search(
      origin: origin,
      originLabel: 'Départ',
      destination: destination,
      destinationLabel: 'Arrivée',
      preferences: TripPreferences.defaults,
    );

    expect(results, isNotEmpty);
  });

  test('planifie le départ à l\'heure demandée plutôt que "maintenant"', () async {
    final departAt = DateTime(2026, 8, 10, 9, 30);
    final results = await service.search(
      origin: origin,
      originLabel: 'Plateau',
      destination: destination,
      destinationLabel: 'Guédiawaye',
      preferences: const TripPreferences(
        preferredModes: {TransportMode.taxi},
        comfortLevel: ComfortLevel.standard,
        maxWalkMinutes: 15,
      ),
      departAt: departAt,
    );

    expect(results.single.departureTime, departAt);
  });

  test('utilise l\'horloge injectée pour le départ "maintenant"', () async {
    final fixedNow = DateTime(2026, 8, 10, 7, 0);
    final clockedService = MockRoutePlanningService(now: () => fixedNow);
    final results = await clockedService.search(
      origin: origin,
      originLabel: 'Plateau',
      destination: destination,
      destinationLabel: 'Guédiawaye',
      preferences: const TripPreferences(
        preferredModes: {TransportMode.taxi},
        comfortLevel: ComfortLevel.standard,
        maxWalkMinutes: 15,
      ),
    );

    expect(results.single.departureTime, fixedNow);
  });

  test('écarte les modes dont le confort est sous le niveau demandé', () async {
    // Plateau -> Hann : bus et tram sont tous deux accessibles à pied dans
    // le budget (marche ~1,6 km max), donc seul le confort les départage.
    // Niveau "confort" (score >= 4) : le tram (4) et le taxi (5) passent,
    // le bus (2) et la navette (3) doivent être écartés.
    const hann = LatLng(14.7139, -17.4392);
    final results = await service.search(
      origin: origin,
      originLabel: 'Plateau',
      destination: hann,
      destinationLabel: 'Hann',
      preferences: const TripPreferences(
        preferredModes: {
          TransportMode.bus,
          TransportMode.tram,
          TransportMode.navette,
          TransportMode.taxi,
        },
        comfortLevel: ComfortLevel.confort,
        maxWalkMinutes: 30,
      ),
    );

    expect(results, isNotEmpty);
    final modes = results.expand((it) => it.primaryModes).toSet();
    // Le tram reste proposé (confort 4, accessible à pied).
    expect(modes, contains(TransportMode.tram));
    // Le bus (confort 2) et la navette (confort 3) sont filtrés par confort.
    expect(modes, isNot(contains(TransportMode.bus)));
    expect(modes, isNot(contains(TransportMode.navette)));
  });

  test('respecte la limite de marche à pied (maxWalkMinutes)', () async {
    // Point en bord de mer, loin de tout arrêt de bus : la marche aller est
    // grande. Avec maxWalkMinutes à 1, aucune ligne ne doit être proposée,
    // seul le taxi porte-à-porte reste possible.
    const beachOrigin = LatLng(14.7315, -17.5075);
    final results = await service.search(
      origin: beachOrigin,
      originLabel: 'Plage',
      destination: destination,
      destinationLabel: 'Guédiawaye',
      preferences: const TripPreferences(
        preferredModes: {
          TransportMode.bus,
          TransportMode.tram,
          TransportMode.navette,
          TransportMode.taxi,
        },
        comfortLevel: ComfortLevel.economique,
        maxWalkMinutes: 1,
      ),
    );

    expect(results, isNotEmpty);
    // Aucun itinéraire ne doit contenir de tronçon motorisé sur ligne fixe
    // (le taxi direct ne marche pas à pied) ; et aucune grosse marche.
    for (final itinerary in results) {
      expect(itinerary.primaryModes, everyElement(TransportMode.taxi));
      for (final leg in itinerary.legs) {
        if (leg.mode == TransportMode.walk) {
          expect(leg.durationMinutes, lessThanOrEqualTo(1));
        }
      }
    }
  });
}
