import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/booking.dart';

/// Persiste réellement les réservations de trajet de chaque utilisateur
/// (identifié par son numéro de téléphone) sur l'appareil, comme
/// `SubscriptionService` le fait pour l'abonnement.
///
/// Point d'intégration API réelle : un vrai module de réservation
/// nécessiterait un backend (création/annulation server-side, place
/// réellement bloquée sur le véhicule) ; ici la réservation ne fait
/// qu'enregistrer l'intention de trajet de l'utilisateur localement.
class BookingService {
  String _key(String phone) => 'sunubus_bookings_$phone';

  Future<List<Booking>> getBookings(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(phone));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBookings(String phone, List<Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bookings.map((b) => b.toJson()).toList());
    await prefs.setString(_key(phone), encoded);
  }
}
