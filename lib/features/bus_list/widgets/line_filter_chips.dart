import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
      height: 48,
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
        color: selected ? Colors.white : AppColors.charbonChaud,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
