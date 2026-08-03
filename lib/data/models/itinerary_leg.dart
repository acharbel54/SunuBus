import 'package:latlong2/latlong.dart';

import 'transport_mode.dart';

/// Un tronçon d'itinéraire : soit un déplacement à pied, soit un trajet sur
/// une ligne motorisée (bus/tram/navette) ou en taxi.
class ItineraryLeg {
  final TransportMode mode;
  final String fromLabel;
  final String toLabel;

  /// Identifiant de la [BusLine] empruntée (`null` pour la marche ou le taxi,
  /// qui ne suivent pas une ligne fixe).
  final String? lineId;

  final int durationMinutes;
  final double priceFcfa;

  /// Points du tracé, utilisés pour dessiner ce tronçon sur l'aperçu carte.
  final List<LatLng> points;

  const ItineraryLeg({
    required this.mode,
    required this.fromLabel,
    required this.toLabel,
    this.lineId,
    required this.durationMinutes,
    required this.priceFcfa,
    required this.points,
  });
}
