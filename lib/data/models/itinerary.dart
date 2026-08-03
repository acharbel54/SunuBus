import 'itinerary_leg.dart';
import 'transport_mode.dart';

/// Un itinéraire complet proposé par la recherche multimodale : une
/// succession de [ItineraryLeg] (marche + un ou plusieurs modes motorisés).
class Itinerary {
  final String id;
  final List<ItineraryLeg> legs;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int totalDurationMinutes;
  final double totalPriceFcfa;

  /// Score de confort de 1 (basique) à 5 (excellent), dérivé du mode
  /// principal et du nombre de correspondances.
  final int comfortScore;

  const Itinerary({
    required this.id,
    required this.legs,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalDurationMinutes,
    required this.totalPriceFcfa,
    required this.comfortScore,
  });

  /// Modes motorisés traversés par cet itinéraire (hors marche), dans l'ordre.
  List<TransportMode> get primaryModes =>
      legs.map((l) => l.mode).where((m) => m != TransportMode.walk).toList();

  int get transfersCount => primaryModes.isEmpty ? 0 : primaryModes.length - 1;
}
