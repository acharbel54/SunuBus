import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/trip_preferences.dart';

/// Persiste les préférences de recherche d'itinéraire (modes de transport,
/// confort, marche max) de chaque utilisateur sur l'appareil.
class PreferencesService {
  String _key(String phone) => 'sunubus_trip_preferences_$phone';

  Future<TripPreferences> getPreferences(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(phone));
    if (raw == null || raw.isEmpty) return TripPreferences.defaults;
    return TripPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePreferences(String phone, TripPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(phone), jsonEncode(preferences.toJson()));
  }
}
