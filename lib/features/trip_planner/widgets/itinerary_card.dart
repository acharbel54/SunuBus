import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/transport_mode.dart';

class ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onTap;

  const ItineraryCard({super.key, required this.itinerary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int i = 0; i < itinerary.legs.length; i++) ...[
                    Icon(itinerary.legs[i].mode.icon, size: 20, color: itinerary.legs[i].mode.color),
                    if (i != itinerary.legs.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.charbonChaud.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                  const Spacer(),
                  _ComfortStars(score: itinerary.comfortScore),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${itinerary.totalDurationMinutes} min',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '· ${DateFormat.Hm('fr_FR').format(itinerary.departureTime)} → ${DateFormat.Hm('fr_FR').format(itinerary.arrivalTime)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.charbonChaud.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${itinerary.totalPriceFcfa.round()} FCFA',
                    style: textTheme.titleMedium?.copyWith(color: AppColors.terracotta),
                  ),
                ],
              ),
              if (itinerary.transfersCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${itinerary.transfersCount} correspondance${itinerary.transfersCount > 1 ? 's' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.charbonChaud.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComfortStars extends StatelessWidget {
  final int score;
  const _ComfortStars({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < score ? Icons.star : Icons.star_border,
            size: 14,
            color: AppColors.ocreProfond,
          ),
      ],
    );
  }
}
