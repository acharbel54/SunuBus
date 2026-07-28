import 'package:latlong2/latlong.dart';

import 'occupancy_level.dart';

/// Représente un bus en circulation, avec sa position et son état,
/// recalculés en continu par `BusSimulationService`.
class Bus {
  /// Identifiant unique du bus (ex: "l4-bus-1").
  final String id;

  /// Identifiant de la [BusLine] à laquelle ce bus appartient.
  final String lineId;

  /// Position GPS actuelle (interpolée entre deux arrêts).
  final LatLng position;

  /// Index de l'arrêt que le bus vient de quitter (dans `BusLine.stops`).
  final int segmentIndex;

  /// Sens de parcours : true = index croissant, false = index décroissant.
  final bool forward;

  /// Progression (0.0 à 1.0) entre l'arrêt `segmentIndex` et le suivant.
  final double segmentProgress;

  /// Nom du prochain arrêt à atteindre.
  final String nextStopName;

  /// Temps estimé (en minutes) avant l'arrivée au prochain arrêt.
  final int etaMinutes;

  /// Niveau de remplissage simulé.
  final OccupancyLevel occupancy;

  const Bus({
    required this.id,
    required this.lineId,
    required this.position,
    required this.segmentIndex,
    required this.forward,
    required this.segmentProgress,
    required this.nextStopName,
    required this.etaMinutes,
    required this.occupancy,
  });

  Bus copyWith({
    LatLng? position,
    int? segmentIndex,
    bool? forward,
    double? segmentProgress,
    String? nextStopName,
    int? etaMinutes,
    OccupancyLevel? occupancy,
  }) {
    return Bus(
      id: id,
      lineId: lineId,
      position: position ?? this.position,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      forward: forward ?? this.forward,
      segmentProgress: segmentProgress ?? this.segmentProgress,
      nextStopName: nextStopName ?? this.nextStopName,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      occupancy: occupancy ?? this.occupancy,
    );
  }
}
