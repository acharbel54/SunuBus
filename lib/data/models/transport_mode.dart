import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Modes de transport disponibles pour la recherche multimodale
/// d'itinéraires ([TransportMode.walk] représente les tronçons de marche
/// entre deux modes motorisés, jamais un mode sélectionnable en filtre).
enum TransportMode { bus, tram, taxi, navette, walk }

extension TransportModeX on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.tram:
        return 'Tram';
      case TransportMode.taxi:
        return 'Taxi';
      case TransportMode.navette:
        return 'Navette';
      case TransportMode.walk:
        return 'Marche';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.tram:
        return Icons.tram;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.navette:
        return Icons.airport_shuttle;
      case TransportMode.walk:
        return Icons.directions_walk;
    }
  }

  Color get color {
    switch (this) {
      case TransportMode.bus:
        return AppColors.terracotta;
      case TransportMode.tram:
        return AppColors.bleuAtlantique;
      case TransportMode.taxi:
        return AppColors.ocreProfond;
      case TransportMode.navette:
        return AppColors.vertBaobab;
      case TransportMode.walk:
        return AppColors.charbonChaud;
    }
  }

  /// Tarif de base (FCFA), facturé indépendamment de la distance.
  double get baseFareFcfa {
    switch (this) {
      case TransportMode.bus:
        return 250;
      case TransportMode.tram:
        return 300;
      case TransportMode.taxi:
        return 500;
      case TransportMode.navette:
        return 300;
      case TransportMode.walk:
        return 0;
    }
  }

  /// Tarif additionnel par kilomètre (FCFA/km), utilisé pour les modes dont
  /// le prix dépend de la distance parcourue (le bus/tram/navette à Dakar
  /// pratiquent en général un tarif fixe par trajet, contrairement au taxi).
  double get farePerKmFcfa {
    switch (this) {
      case TransportMode.taxi:
        return 300;
      case TransportMode.bus:
      case TransportMode.tram:
      case TransportMode.navette:
      case TransportMode.walk:
        return 0;
    }
  }

  /// Vitesse moyenne (km/h) utilisée pour estimer la durée d'un tronçon.
  double get averageSpeedKmh {
    switch (this) {
      case TransportMode.bus:
        return 18;
      case TransportMode.tram:
        return 22;
      case TransportMode.taxi:
        return 28;
      case TransportMode.navette:
        return 20;
      case TransportMode.walk:
        return 4.8;
    }
  }
}
