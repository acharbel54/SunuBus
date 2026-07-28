import 'package:latlong2/latlong.dart';

/// Un arrêt de bus le long d'un trajet.
class BusStop {
  final String id;
  final String name;
  final LatLng position;

  const BusStop({
    required this.id,
    required this.name,
    required this.position,
  });
}
