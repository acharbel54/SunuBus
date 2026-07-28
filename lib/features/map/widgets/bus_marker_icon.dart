import 'package:flutter/material.dart';

import '../../../data/models/bus_line.dart';

/// Icône ronde et colorée représentant un bus sur la carte, avec le code
/// court de sa ligne (ex: "4", "75", "DD").
class BusMarkerIcon extends StatelessWidget {
  final BusLine line;

  const BusMarkerIcon({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: line.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.directions_bus, color: Colors.white, size: 16),
      ),
    );
  }
}
