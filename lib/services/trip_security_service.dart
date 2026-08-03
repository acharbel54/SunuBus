import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/emergency_contact.dart';

/// Sécurisation des trajets : contact d'urgence persisté par utilisateur, et
/// construction du message de partage de trajet ("Partager mon trajet").
///
/// Point d'intégration API réelle : en production, le partage de trajet et
/// le bouton SOS s'appuieraient sur une vraie passerelle d'envoi (SMS via un
/// fournisseur type Twilio, ou le panneau de partage natif du système via
/// le package `share_plus`) plutôt que sur une simulation locale.
class TripSecurityService {
  String _key(String phone) => 'sunubus_emergency_contact_$phone';

  Future<EmergencyContact?> getContact(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(phone));
    if (raw == null || raw.isEmpty) return null;
    return EmergencyContact.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveContact(String phone, EmergencyContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(phone), jsonEncode(contact.toJson()));
  }

  Future<void> clearContact(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(phone));
  }

  String buildTripShareMessage({
    required String originLabel,
    required String destinationLabel,
    required String modeLabel,
    required DateTime arrivalTime,
  }) {
    final arrival =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
    return 'Je suis en trajet SunuBus de $originLabel à $destinationLabel en $modeLabel, '
        'arrivée prévue vers $arrival.';
  }
}
