import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/itinerary.dart';
import '../data/models/trip_preferences.dart';
import '../services/route_planning_service.dart';
import 'auth_providers.dart';
import 'preferences_providers.dart';

/// Un point choisi (origine ou destination) pour la recherche d'itinéraire.
class TripPoint {
  final LatLng position;
  final String label;
  const TripPoint(this.position, this.label);
}

enum ItinerarySort { price, duration, comfort }

extension ItinerarySortX on ItinerarySort {
  String get label {
    switch (this) {
      case ItinerarySort.price:
        return 'Prix';
      case ItinerarySort.duration:
        return 'Durée';
      case ItinerarySort.comfort:
        return 'Confort';
    }
  }
}

final routePlanningServiceProvider = Provider<RoutePlanningApi>((ref) => MockRoutePlanningService());

final originProvider = StateProvider<TripPoint?>((ref) => null);
final destinationProvider = StateProvider<TripPoint?>((ref) => null);

/// `null` signifie "partir maintenant" ; une valeur non nulle correspond à
/// une planification à l'avance choisie par l'utilisateur.
final departAtProvider = StateProvider<DateTime?>((ref) => null);

final itinerarySortProvider = StateProvider<ItinerarySort>((ref) => ItinerarySort.duration);

/// Résultats de recherche multimodale, recalculés dès que l'origine, la
/// destination, l'heure de départ, les préférences ou le tri changent.
final searchResultsProvider = FutureProvider.autoDispose<List<Itinerary>>((ref) async {
  final origin = ref.watch(originProvider);
  final destination = ref.watch(destinationProvider);
  if (origin == null || destination == null) return const [];

  final phone = ref.watch(authControllerProvider).phone;
  final preferences = phone == null
      ? TripPreferences.defaults
      : ref.watch(tripPreferencesControllerProvider(phone));

  final service = ref.watch(routePlanningServiceProvider);
  final results = await service.search(
    origin: origin.position,
    originLabel: origin.label,
    destination: destination.position,
    destinationLabel: destination.label,
    preferences: preferences,
    departAt: ref.watch(departAtProvider),
  );

  final sort = ref.watch(itinerarySortProvider);
  final sorted = [...results];
  switch (sort) {
    case ItinerarySort.price:
      sorted.sort((a, b) => a.totalPriceFcfa.compareTo(b.totalPriceFcfa));
      break;
    case ItinerarySort.duration:
      sorted.sort((a, b) => a.totalDurationMinutes.compareTo(b.totalDurationMinutes));
      break;
    case ItinerarySort.comfort:
      sorted.sort((a, b) => b.comfortScore.compareTo(a.comfortScore));
      break;
  }
  return sorted;
});
