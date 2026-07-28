import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: line.color,
                  child: Text(
                    line.shortCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bus n° ${bus.id.split('-').last}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _InfoRow(
              icon: Icons.directions_bus_filled_outlined,
              label: 'Prochain arrêt',
              value: bus.nextStopName,
            ),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Arrivée estimée',
              value: '${bus.etaMinutes} min',
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
