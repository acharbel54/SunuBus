import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/geolocation_service.dart';

final geolocationServiceProvider = Provider<GeolocationService>((ref) => GeolocationService());

/// Position actuelle de l'appareil, recalculée à chaque `ref.refresh` (ex:
/// quand l'utilisateur appuie sur "Ma position").
final currentPositionProvider = FutureProvider.autoDispose<LocationResult>((ref) {
  return ref.watch(geolocationServiceProvider).getCurrentPosition();
});
