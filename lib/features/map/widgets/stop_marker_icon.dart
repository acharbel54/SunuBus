import 'package:flutter/material.dart';

/// Petit marqueur circulaire représentant un arrêt de bus fixe sur la carte.
class StopMarkerIcon extends StatelessWidget {
  const StopMarkerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF616161), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.circle, size: 5, color: Color(0xFF616161)),
      ),
    );
  }
}
