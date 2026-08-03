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
}
