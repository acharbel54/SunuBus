import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Résultat d'une tentative de géolocalisation : soit une position, soit une
/// raison d'échec exploitable pour l'affichage (permission refusée, service
/// désactivé, etc.).
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final LatLng position;
  LocationSuccess(this.position);
}

class LocationFailure extends LocationResult {
  final String reason;
  LocationFailure(this.reason);
}

/// Seul module de cette fonctionnalité à appeler une véritable API device :
/// `geolocator` interroge le capteur GPS réel de l'appareil (contrairement
/// au reste de l'app, entièrement simulé).
class GeolocationService {
  /// Position simulée (centre de Dakar) utilisée sur les plateformes de
  /// bureau où `geolocator` n'a pas de canal natif (Linux/Windows) : on
  /// renvoie une position plausible plutôt qu'un échec silencieux.
  static const LatLng _dakarFallback = LatLng(14.735, -17.455);

  /// Vrai sur Linux/Windows (desktop), où le capteur GPS n'existe pas.
  bool get _isDesktopWithoutGps {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<LocationResult> getCurrentPosition() async {
    // Sur desktop, `geolocator` échoue silencieusement : on renvoie une
    // position simulée pour que la recherche "Ma position" reste utilisable.
    if (_isDesktopWithoutGps) {
      return LocationSuccess(_dakarFallback);
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationFailure('La localisation est désactivée sur cet appareil.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationFailure('Permission de localisation refusée.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationFailure(
        'Permission de localisation bloquée. Autorisez-la dans les réglages.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LocationSuccess(LatLng(position.latitude, position.longitude));
    } catch (_) {
      return LocationFailure('Impossible d\'obtenir la position actuelle.');
    }
  }
}
