import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transport_mode.dart';
import '../data/models/trip_preferences.dart';
import '../services/preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) => PreferencesService());

/// Préférences de recherche d'itinéraire de l'utilisateur connecté, chargées
/// depuis l'appareil puis tenues à jour à chaque modification.
class TripPreferencesController extends StateNotifier<TripPreferences> {
  final PreferencesService _service;
  final String phone;

  TripPreferencesController(this._service, this.phone) : super(TripPreferences.defaults) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getPreferences(phone);
  }

  Future<void> toggleMode(TransportMode mode) async {
    final modes = Set<TransportMode>.from(state.preferredModes);
    if (modes.contains(mode)) {
      // Toujours garder au moins un mode actif.
      if (modes.length > 1) modes.remove(mode);
    } else {
      modes.add(mode);
    }
    state = state.copyWith(preferredModes: modes);
    await _service.savePreferences(phone, state);
  }

  Future<void> setComfortLevel(ComfortLevel level) async {
    state = state.copyWith(comfortLevel: level);
    await _service.savePreferences(phone, state);
  }

  Future<void> setMaxWalkMinutes(int minutes) async {
    state = state.copyWith(maxWalkMinutes: minutes);
    await _service.savePreferences(phone, state);
  }
}

final tripPreferencesControllerProvider =
    StateNotifierProvider.family<TripPreferencesController, TripPreferences, String>(
  (ref, phone) => TripPreferencesController(ref.watch(preferencesServiceProvider), phone),
);
