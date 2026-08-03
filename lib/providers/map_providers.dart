import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fournisseur de tuiles de la carte OpenStreetMap. `null` (valeur par
/// défaut) laisse `flutter_map` utiliser son `NetworkTileProvider` habituel.
/// Surchargé dans les tests widgets pour éviter toute requête réseau réelle
/// vers `tile.openstreetmap.org`.
final mapTileProviderProvider = Provider<TileProvider?>((ref) => null);
