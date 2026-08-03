import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/bus_line.dart';

/// Marqueur de bus sur la carte : un halo qui respire en continu derrière un
/// badge à la forme organique (coins asymétriques plutôt qu'un cercle
/// parfait), pour donner une impression de véhicule vivant plutôt qu'un pin
/// générique statique.
class BusMarkerIcon extends StatefulWidget {
  final BusLine line;

  const BusMarkerIcon({super.key, required this.line});

  @override
  State<BusMarkerIcon> createState() => _BusMarkerIconState();
}

class _BusMarkerIconState extends State<BusMarkerIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final t = _pulseController.value;
          final haloScale = 0.6 + t * 0.7;
          final haloOpacity = (1 - t) * 0.35;
          final breathe = 1.0 + 0.045 * math.sin(t * 2 * math.pi);

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: haloScale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.line.color.withValues(alpha: haloOpacity),
                  ),
                ),
              ),
              Transform.scale(scale: breathe, child: child),
            ],
          );
        },
        child: _BusBadge(line: widget.line),
      ),
    );
  }
}

class _BusBadge extends StatelessWidget {
  final BusLine line;

  const _BusBadge({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: line.color,
        // Coins arrondis asymétriques : silhouette organique, pas un cercle
        // géométrique parfait.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.sableCarte, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.charbonChaud.withValues(alpha: 0.32),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.directions_bus_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}
