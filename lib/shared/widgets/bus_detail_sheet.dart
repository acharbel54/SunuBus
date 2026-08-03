import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bus.dart';
import '../../data/models/bus_line.dart';
import '../../data/models/occupancy_level.dart';

/// Ouvre un panneau modal affichant le détail d'un bus : ligne, prochain
/// arrêt, ETA et taux de remplissage.
void showBusDetailSheet(
  BuildContext context, {
  required Bus bus,
  required BusLine line,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => BusDetailSheet(bus: bus, line: line),
  );
}

class BusDetailSheet extends StatelessWidget {
  final Bus bus;
  final BusLine line;

  const BusDetailSheet({super.key, required this.bus, required this.line});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.sableBordure,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: line.color,
                  child: Text(
                    line.shortCode,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.displayName, style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Bus n° ${bus.id.split('-').last}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.charbonChaud.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Bloc ETA mis en avant : information la plus utile de la fiche.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arrivée estimée',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.charbonChaud.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${bus.etaMinutes}',
                              style: textTheme.headlineMedium?.copyWith(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'min · vers ${bus.nextStopName}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.charbonChaud.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.timer_outlined,
                    size: 34,
                    color: AppColors.terracotta.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: bus.occupancy.icon,
              label: 'Remplissage',
              value: bus.occupancy.label,
              valueColor: bus.occupancy.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.charbonChaud.withValues(alpha: 0.55)),
          const SizedBox(width: 14),
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
