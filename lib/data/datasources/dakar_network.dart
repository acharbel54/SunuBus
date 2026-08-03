import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';

/// Jeu de données statiques (mock) représentant un réseau de transport en
/// commun simplifié de Dakar : 3 lignes, avec des arrêts positionnés sur
/// des coordonnées réelles (ou très proches) de quartiers de Dakar.
///
/// Ces trajets sont fictifs (ils ne suivent pas exactement la voirie réelle)
/// mais respectent la géographie générale de la ville, ce qui suffit pour
/// une démonstration de suivi en temps réel sans données GPS réelles.
class DakarNetwork {
  DakarNetwork._();

  // ---------------------------------------------------------------------
  // Ligne 4 (Tata) : Colobane -> Grand Yoff -> Parcelles Assainies -> Guédiawaye
  // ---------------------------------------------------------------------
  static const BusLine ligne4 = BusLine(
    id: 'ligne-4',
    number: 'Ligne 4',
    operatorName: 'Tata',
    color: AppColors.terracotta,
    stops: [
      BusStop(id: 'colobane', name: 'Colobane', position: LatLng(14.7167, -17.4530)),
      BusStop(id: 'hlm', name: 'HLM', position: LatLng(14.6950, -17.4470)),
      BusStop(id: 'dieuppeul', name: 'Dieuppeul', position: LatLng(14.7080, -17.4530)),
      BusStop(id: 'grand-yoff', name: 'Grand Yoff', position: LatLng(14.7280, -17.4590)),
      BusStop(id: 'liberte-6', name: 'Liberté 6', position: LatLng(14.7245, -17.4577)),
      BusStop(id: 'parcelles', name: 'Parcelles Assainies', position: LatLng(14.7654, -17.4270)),
      BusStop(id: 'guediawaye', name: 'Guédiawaye', position: LatLng(14.7730, -17.4090)),
    ],
  );

  // ---------------------------------------------------------------------
  // Ligne 75 (Tata) : Plateau -> Petersen -> Front de Terre -> Grand Yoff -> Pikine
  // ---------------------------------------------------------------------
  static const BusLine ligne75 = BusLine(
    id: 'ligne-75',
    number: 'Ligne 75',
    operatorName: 'Tata',
    color: AppColors.bleuAtlantique,
    stops: [
      BusStop(id: 'plateau', name: 'Plateau', position: LatLng(14.6714, -17.4383)),
      BusStop(id: 'petersen', name: 'Petersen', position: LatLng(14.6708, -17.4402)),
      BusStop(id: 'castors', name: 'Castors', position: LatLng(14.7180, -17.4460)),
      BusStop(id: 'front-de-terre', name: 'Front de Terre', position: LatLng(14.7269, -17.4470)),
      BusStop(id: 'sacre-coeur', name: 'Sacré-Cœur', position: LatLng(14.7169, -17.4650)),
      BusStop(id: 'grand-yoff-2', name: 'Grand Yoff', position: LatLng(14.7280, -17.4590)),
      BusStop(id: 'pikine', name: 'Pikine', position: LatLng(14.7547, -17.3900)),
    ],
  );

  // ---------------------------------------------------------------------
  // Dem Dikk : Petersen -> Plateau -> Ouakam -> Yoff
  // ---------------------------------------------------------------------
  static const BusLine demDikk = BusLine(
    id: 'dem-dikk',
    number: 'Dem Dikk',
    operatorName: 'Dem Dikk',
    color: AppColors.vertBaobab,
    stops: [
      BusStop(id: 'petersen-2', name: 'Petersen', position: LatLng(14.6708, -17.4402)),
      BusStop(id: 'plateau-2', name: 'Plateau', position: LatLng(14.6714, -17.4383)),
      BusStop(id: 'mermoz', name: 'Mermoz', position: LatLng(14.7050, -17.4750)),
      BusStop(id: 'ouakam', name: 'Ouakam', position: LatLng(14.7167, -17.4833)),
      BusStop(id: 'yoff', name: 'Yoff', position: LatLng(14.7500, -17.4833)),
    ],
  );

  static const List<BusLine> lines = [ligne4, ligne75, demDikk];

  static BusLine lineById(String id) => lines.firstWhere((l) => l.id == id);

  /// Liste dédupliquée de tous les arrêts du réseau (certaines lignes
  /// partagent physiquement le même arrêt, ex: "Grand Yoff" ou "Plateau").
  static List<BusStop> get allStops {
    final Map<String, BusStop> byName = {};
    for (final line in lines) {
      for (final stop in line.stops) {
        byName[stop.name] = stop;
      }
    }
    return byName.values.toList();
  }
}
