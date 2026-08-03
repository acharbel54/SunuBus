import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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
        return AppColors.vertBaobab;
      case OccupancyLevel.medium:
        return AppColors.ocreProfond;
      case OccupancyLevel.high:
        return AppColors.rouilleAlerte;
      case OccupancyLevel.full:
        return AppColors.briqueSature;
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
