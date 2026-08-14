import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/dakar_network.dart';
import '../data/models/bus.dart';
import '../data/models/bus_line.dart';
import '../services/bus_simulation_service.dart';

/// Fait tourner la simulation et expose la liste des bus, mise à jour
/// automatiquement toutes les ~2,5 secondes.
/// `autoDispose` : le timer est coupé dès que plus personne n'écoute le
/// provider (ex: écran carte fermé), évitant une simulation en arrière-plan
/// qui gaspillerait la batterie.
/// Note : pas besoin d'appeler `service.dispose()` manuellement ici —
/// `StateNotifierProvider` s'en charge déjà automatiquement (un double
/// appel provoquerait une erreur "used after dispose").
final busSimulationProvider =
    StateNotifierProvider.autoDispose<BusSimulationService, List<Bus>>((ref) {
  final service = BusSimulationService();
  return service;
});

/// Liste statique des lignes disponibles (référentiel, ne change pas).
final busLinesProvider = Provider<List<BusLine>>((ref) => DakarNetwork.lines);

/// Ligne actuellement sélectionnée dans le filtre du panneau inférieur.
/// `null` signifie "toutes les lignes".
final selectedLineFilterProvider = StateProvider<String?>((ref) => null);

/// Texte de recherche d'arrêt saisi par l'utilisateur.
final stopSearchQueryProvider = StateProvider<String>((ref) => '');

/// Liste des bus filtrée par ligne sélectionnée, triée par ETA croissant.
/// `autoDispose` comme `busSimulationProvider` : sans ça, ce provider ne
/// serait jamais détruit et garderait indéfiniment un abonnement à
/// `busSimulationProvider`, empêchant SON `autoDispose` de jamais se
/// déclencher (le timer de simulation tournerait en continu, y compris
/// après déconnexion).
final filteredBusesProvider = Provider.autoDispose<List<Bus>>((ref) {
  final buses = ref.watch(busSimulationProvider);
  final lineFilter = ref.watch(selectedLineFilterProvider);

  final filtered = lineFilter == null
      ? buses
      : buses.where((bus) => bus.lineId == lineFilter).toList();

  final sorted = [...filtered]..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  return sorted;
});

/// Arrêts correspondant à la recherche de l'utilisateur (par nom), avec les
/// lignes qui les desservent.
final stopSearchResultsProvider = Provider<List<StopSearchResult>>((ref) {
  final query = ref.watch(stopSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return const [];

  final results = <StopSearchResult>[];
  for (final stop in DakarNetwork.allStops) {
    if (stop.name.toLowerCase().contains(query)) {
      final servingLines = DakarNetwork.lines
          .where((line) => line.stops.any((s) => s.name == stop.name))
          .toList();
      results.add(StopSearchResult(stopName: stop.name, lines: servingLines));
    }
  }
  return results;
});

class StopSearchResult {
  final String stopName;
  final List<BusLine> lines;

  const StopSearchResult({required this.stopName, required this.lines});
}
