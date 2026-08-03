import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/transport_mode.dart';

class BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;

  const BookingTile({super.key, required this.booking, this.onCancel});

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return AppColors.vertBaobab;
      case BookingStatus.completed:
        return AppColors.bleuAtlantique;
      case BookingStatus.cancelled:
        return AppColors.charbonChaud.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: booking.primaryMode.color.withValues(alpha: 0.15),
              child: Icon(booking.primaryMode.icon, color: booking.primaryMode.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.originLabel} → ${booking.destinationLabel}',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(booking.scheduledAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.charbonChaud.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.status.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${booking.priceFcfa.round()} FCFA', style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            if (onCancel != null)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Annuler',
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }
}
