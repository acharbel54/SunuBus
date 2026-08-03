import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/booking_providers.dart';
import '../widgets/booking_tile.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(authControllerProvider).phone!;
    final bookings = ref.watch(bookingControllerProvider(phone));
    final textTheme = Theme.of(context).textTheme;

    final upcoming = bookings.where((b) => b.status == BookingStatus.upcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = bookings.where((b) => b.status != BookingStatus.upcoming).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes réservations')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucune réservation pour le moment.\nPlanifiez un trajet pour en créer une.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.charbonChaud.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (upcoming.isNotEmpty) ...[
              Text('À venir', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final booking in upcoming) ...[
                BookingTile(
                  booking: booking,
                  onCancel: () =>
                      ref.read(bookingControllerProvider(phone).notifier).cancel(booking.id),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
            ],
            if (past.isNotEmpty) ...[
              Text('Historique', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final booking in past) ...[
                BookingTile(booking: booking),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
