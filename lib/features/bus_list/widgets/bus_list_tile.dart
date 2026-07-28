import 'package:flutter/material.dart';

import '../../../data/models/bus.dart';
import '../../../data/models/bus_line.dart';
import '../../../data/models/occupancy_level.dart';

/// Ligne de la liste des bus actifs : ligne, prochain arrêt, ETA et
/// remplissage.
class BusListTile extends StatelessWidget {
  final Bus bus;
  final BusLine line;
  final VoidCallback onTap;

  const BusListTile({
    super.key,
    required this.bus,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: line.color,
          child: Text(
            line.shortCode,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          line.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('Vers ${bus.nextStopName} · ${bus.etaMinutes} min'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(bus.occupancy.icon, size: 18, color: bus.occupancy.color),
            const SizedBox(height: 2),
            Text(
              bus.occupancy.label,
              style: TextStyle(fontSize: 10, color: bus.occupancy.color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
