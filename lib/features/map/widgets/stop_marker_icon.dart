import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Petit marqueur représentant un arrêt de bus fixe sur la carte : une
/// goutte de sable cerclée d'ocre, discrète mais visible sur le fond de
/// carte clair.
class StopMarkerIcon extends StatelessWidget {
  const StopMarkerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sableCarte,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ocreProfond, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.charbonChaud.withValues(alpha: 0.18),
            blurRadius: 3,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.circle, size: 5, color: AppColors.ocreProfond),
      ),
    );
  }
}
