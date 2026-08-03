import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/dakar_network.dart';
import '../../../data/models/bus.dart';
import '../../../providers/bus_providers.dart';
import 'bus_list_tile.dart';
import 'line_filter_chips.dart';
import 'search_stop_field.dart';
import 'stop_search_result_tile.dart';
import 'subscription_banner.dart';

/// Contenu du panneau inférieur rétractable (DraggableScrollableSheet) :
/// poignée, recherche d'arrêt, filtre par ligne, liste des bus actifs et
/// bannière d'abonnement.
class BusListPanel extends ConsumerWidget {
  final ScrollController scrollController;
  final void Function(Bus bus) onBusTap;

  const BusListPanel({
    super.key,
    required this.scrollController,
    required this.onBusTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(busLinesProvider);
    final buses = ref.watch(filteredBusesProvider);
    final searchQuery = ref.watch(stopSearchQueryProvider);
    final searchResults = ref.watch(stopSearchResultsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sableClair,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: AppColors.charbonChaud.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.sableBordure,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SearchStopField(),
          const SizedBox(height: 16),
          LineFilterChips(lines: lines),
          const SizedBox(height: 22),

          if (searchQuery.isNotEmpty) ...[
            Text(
              'Résultats pour « $searchQuery »',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aucun arrêt ne correspond à cette recherche.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final result in searchResults) StopSearchResultTile(result: result),
            const Divider(height: 40),
          ],

          Text(
            'Bus actifs (${buses.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          if (buses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun bus actif sur cette ligne pour le moment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final bus in buses)
              BusListTile(
                bus: bus,
                line: DakarNetwork.lineById(bus.lineId),
                onTap: () => onBusTap(bus),
              ),

          const SizedBox(height: 16),
          const SubscriptionBanner(),
        ],
      ),
    );
  }
}
