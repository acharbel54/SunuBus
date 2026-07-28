import 'package:flutter/material.dart';

/// Niveau de remplissage estimé d'un bus.
///
/// En l'absence de capteurs physiques (compteurs de passagers), ce niveau
/// est simulé aléatoirement par [BusSimulationService] et évolue dans le
/// temps pour donner une impression réaliste de fréquentation.
enum OccupancyLevel { low, medium, high, full }

extension OccupancyLevelX on OccupancyLevel {
  String get label {
    switch (this) {
      case OccupancyLevel.low:
        return 'Places disponibles';
      case OccupancyLevel.medium:
        return 'Quelques places';
      case OccupancyLevel.high:
        return 'Presque plein';
      case OccupancyLevel.full:
        return 'Complet';
    }
  }

  Color get color {
    switch (this) {
      case OccupancyLevel.low:
        return const Color(0xFF2E7D32); // vert
      case OccupancyLevel.medium:
        return const Color(0xFFF9A825); // jaune/orange
      case OccupancyLevel.high:
        return const Color(0xFFEF6C00); // orange foncé
      case OccupancyLevel.full:
        return const Color(0xFFC62828); // rouge
    }
  }

  IconData get icon {
    switch (this) {
      case OccupancyLevel.low:
        return Icons.event_seat;
      case OccupancyLevel.medium:
        return Icons.people_outline;
      case OccupancyLevel.high:
        return Icons.people;
      case OccupancyLevel.full:
        return Icons.block;
    }
  }
}
