import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/transport_mode.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/booking_providers.dart';
import '../../../providers/notification_providers.dart';
import 'my_bookings_screen.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  late bool _reminderEnabled = widget.booking.reminderEnabled;

  Future<void> _toggleReminder(bool enabled) async {
    final phone = ref.read(authControllerProvider).phone!;
    setState(() => _reminderEnabled = enabled);
    await ref.read(bookingControllerProvider(phone).notifier).setReminder(widget.booking.id, enabled);

    final notifications = ref.read(notificationServiceProvider);
    final notificationId = widget.booking.id.hashCode;
    if (enabled) {
      final reminderAt = widget.booking.scheduledAt.subtract(const Duration(minutes: 15));
      await notifications.scheduleTripReminder(
        id: notificationId,
        title: 'Départ imminent',
        body:
            '${widget.booking.originLabel} → ${widget.booking.destinationLabel} dans 15 minutes.',
        scheduledAt: reminderAt,
      );
    } else {
      await notifications.cancelReminder(notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Réservation confirmée')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: Icon(Icons.check_circle, color: AppColors.vertBaobab, size: 64),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Trajet réservé',
                style: textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sableCarte,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(booking.primaryMode.icon, color: booking.primaryMode.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${booking.originLabel} → ${booking.destinationLabel}',
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _Row('Départ', DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(booking.scheduledAt)),
                  _Row('Durée estimée', '${booking.durationMinutes} min'),
                  _Row('Prix', '${booking.priceFcfa.round()} FCFA'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rappel avant le départ'),
              subtitle: const Text('Notification 15 minutes avant l\'heure de départ'),
              value: _reminderEnabled,
              onChanged: _toggleReminder,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Voir mes réservations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
