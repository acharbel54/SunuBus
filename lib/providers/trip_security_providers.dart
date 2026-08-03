import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/emergency_contact.dart';
import '../services/trip_security_service.dart';

final tripSecurityServiceProvider = Provider<TripSecurityService>((ref) => TripSecurityService());

/// Contact d'urgence de l'utilisateur connecté, chargé depuis l'appareil.
class EmergencyContactController extends StateNotifier<EmergencyContact?> {
  final TripSecurityService _service;
  final String phone;

  EmergencyContactController(this._service, this.phone) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getContact(phone);
  }

  Future<void> save(EmergencyContact contact) async {
    state = contact;
    await _service.saveContact(phone, contact);
  }

  Future<void> clear() async {
    state = null;
    await _service.clearContact(phone);
  }
}

final emergencyContactControllerProvider =
    StateNotifierProvider.family<EmergencyContactController, EmergencyContact?, String>(
  (ref, phone) => EmergencyContactController(ref.watch(tripSecurityServiceProvider), phone),
);
