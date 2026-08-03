import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/trip_planner_providers.dart';
import '../widgets/itinerary_card.dart';
import 'itinerary_detail_screen.dart';

class TripResultsScreen extends ConsumerWidget {
  const TripResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final sort = ref.watch(itinerarySortProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Itinéraires proposés')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  for (final option in ItinerarySort.values) ...[
                    ChoiceChip(
                      label: Text('Trier : ${option.label}'),
                      selected: sort == option,
                      onSelected: (_) => ref.read(itinerarySortProvider.notifier).state = option,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    "Impossible de calculer d'itinéraire pour le moment.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                data: (itineraries) {
                  if (itineraries.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun itinéraire trouvé pour ces critères.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.charbonChaud.withValues(alpha: 0.6),
                            ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: itineraries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final itinerary = itineraries[index];
                      return ItineraryCard(
                        itinerary: itinerary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItineraryDetailScreen(itinerary: itinerary),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
