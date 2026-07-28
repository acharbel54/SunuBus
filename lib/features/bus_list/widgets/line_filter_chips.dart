import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bus_line.dart';
import '../../../providers/bus_providers.dart';

/// Rangée de filtres horizontaux permettant d'afficher soit toutes les
/// lignes, soit uniquement les bus d'une ligne précise.
class LineFilterChips extends ConsumerWidget {
  final List<BusLine> lines;

  const LineFilterChips({super.key, required this.lines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLineId = ref.watch(selectedLineFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Toutes les lignes',
            color: Theme.of(context).colorScheme.primary,
            selected: selectedLineId == null,
            onTap: () => ref.read(selectedLineFilterProvider.notifier).state = null,
          ),
          for (final line in lines) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: line.displayName,
              color: line.color,
              selected: selectedLineId == line.id,
              onTap: () => ref.read(selectedLineFilterProvider.notifier).state = line.id,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
