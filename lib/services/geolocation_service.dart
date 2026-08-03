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
  Future<LocationResult> getCurrentPosition() async {
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
