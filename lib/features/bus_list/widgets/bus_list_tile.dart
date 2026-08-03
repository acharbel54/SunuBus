import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/bus.dart';
import '../../../data/models/bus_line.dart';
import '../../../data/models/occupancy_level.dart';

/// Ligne de la liste des bus actifs. Hiérarchie visuelle en trois temps :
/// la ligne (titre, police de caractère), le prochain arrêt et le
/// remplissage (corps de texte discret), puis l'ETA mis en avant comme un
/// gros chiffre d'accent.
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.sableCarte,
        elevation: 2,
        shadowColor: AppColors.charbonChaud.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: line.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                CircleAvatar(
                  radius: 19,
                  backgroundColor: line.color,
                  child: Text(
                    line.shortCode,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.displayName,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Vers ${bus.nextStopName}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.charbonChaud.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(bus.occupancy.icon, size: 14, color: bus.occupancy.color),
                          const SizedBox(width: 5),
                          Text(
                            bus.occupancy.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: bus.occupancy.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bus.etaMinutes}',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'min',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.charbonChaud.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
