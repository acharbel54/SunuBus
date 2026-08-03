import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/models/transport_mode.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/booking_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/trip_security_providers.dart';

/// Sécurisation des trajets : contact d'urgence, partage du trajet en cours,
/// bouton SOS. Tout est simulé localement (voir `TripSecurityService`).
class TripSecurityScreen extends ConsumerStatefulWidget {
  const TripSecurityScreen({super.key});

  @override
  ConsumerState<TripSecurityScreen> createState() => _TripSecurityScreenState();
}

class _TripSecurityScreenState extends ConsumerState<TripSecurityScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(EmergencyContact? contact) {
    if (_prefilled || contact == null) return;
    _nameController.text = contact.name;
    _phoneController.text = contact.phone;
    _prefilled = true;
  }

  Future<void> _saveContact(String phone) async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) return;
    await ref.read(emergencyContactControllerProvider(phone).notifier).save(
          EmergencyContact(name: _nameController.text.trim(), phone: _phoneController.text.trim()),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Contact d\'urgence enregistré.')));
  }

  Future<void> _shareTrip(String phone, Booking booking) async {
    final message = ref.read(tripSecurityServiceProvider).buildTripShareMessage(
          originLabel: booking.originLabel,
          destinationLabel: booking.destinationLabel,
          modeLabel: booking.primaryMode.label,
          arrivalTime: booking.scheduledAt.add(Duration(minutes: booking.durationMinutes)),
        );
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Trajet partagé : message copié (simulation, pas d\'envoi réel).'),
      ));
  }

  Future<void> _sendSos(String phone, EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer une alerte SOS ?'),
        content: Text('${contact.name} sera notifié·e que vous avez besoin d\'aide (simulation).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.briqueSature),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notificationServiceProvider).notifySosSent(contact.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alerte envoyée (simulation).')));
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(authControllerProvider).phone!;
    final contact = ref.watch(emergencyContactControllerProvider(phone));
    final bookings = ref.watch(bookingControllerProvider(phone));
    final textTheme = Theme.of(context).textTheme;

    _prefillIfNeeded(contact);

    final upcoming = bookings.where((b) => b.status == BookingStatus.upcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final activeBooking = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité des trajets')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Contact d\'urgence', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Nom du contact'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Numéro de téléphone'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _saveContact(phone),
              child: const Text('Enregistrer le contact'),
            ),
            const SizedBox(height: 28),
            Text('Partager mon trajet', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            if (activeBooking == null)
              Text(
                'Aucun trajet à venir à partager.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.charbonChaud.withValues(alpha: 0.55),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sableCarte,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${activeBooking.originLabel} → ${activeBooking.destinationLabel}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _shareTrip(phone, activeBooking),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Partager'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            Text('En cas d\'urgence', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.briqueSature),
                onPressed: contact == null ? null : () => _sendSos(phone, contact),
                icon: const Icon(Icons.sos),
                label: const Text('Envoyer une alerte SOS'),
              ),
            ),
            if (contact == null) ...[
              const SizedBox(height: 8),
              Text(
                'Enregistrez un contact d\'urgence pour activer le SOS.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.charbonChaud.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
