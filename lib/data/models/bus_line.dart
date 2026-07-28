import 'package:flutter/material.dart';

import 'bus_stop.dart';

/// Une ligne de bus (ex: "Ligne 4" exploitée par "Tata", ou "Dem Dikk").
///
/// [stops] représente le trajet ordonné : les bus de cette ligne circulent
/// d'un arrêt au suivant, puis font demi-tour une fois au terminus.
class BusLine {
  final String id;
  final String number; // ex: "Ligne 4", "Ligne 75", "Express"
  final String operatorName; // ex: "Tata", "Dem Dikk"
  final Color color;
  final List<BusStop> stops;

  const BusLine({
    required this.id,
    required this.number,
    required this.operatorName,
    required this.color,
    required this.stops,
  });

  String get displayName => '$number · $operatorName';

  /// Code court utilisé pour l'écusson affiché sur les marqueurs de la carte
  /// (ex: "Ligne 4" -> "4", "Dem Dikk" -> "DD").
  String get shortCode {
    final digits = RegExp(r'\d+').firstMatch(number)?.group(0);
    if (digits != null) return digits;
    return number
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .join()
        .toUpperCase();
  }
}
