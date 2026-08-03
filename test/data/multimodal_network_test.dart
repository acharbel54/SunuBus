import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sunu_bus/data/datasources/multimodal_network.dart';
import 'package:sunu_bus/data/models/transport_mode.dart';

void main() {
  test('estimatedPriceFcfa augmente avec la distance pour le taxi', () {
    final short = MultimodalNetwork.estimatedPriceFcfa(TransportMode.taxi, 1);
    final long = MultimodalNetwork.estimatedPriceFcfa(TransportMode.taxi, 10);
    expect(long, greaterThan(short));
  });

  test('estimatedPriceFcfa reste fixe pour le bus quelle que soit la distance', () {
    final short = MultimodalNetwork.estimatedPriceFcfa(TransportMode.bus, 1);
    final long = MultimodalNetwork.estimatedPriceFcfa(TransportMode.bus, 10);
    expect(long, short);
  });

  test('nearest() trouve bien le point le plus proche', () {
    final result = MultimodalNetwork.nearest(
      const LatLng(14.6714, -17.4383), // Plateau
      MultimodalNetwork.taxiStations,
    );
    expect(result.key.name, contains('Plateau'));
    expect(result.value, lessThan(1)); // à moins d'1 km du Plateau
  });

  test('allKnownLocations ne contient pas de doublons de nom', () {
    final names = MultimodalNetwork.allKnownLocations.map((s) => s.name).toList();
    expect(names.length, names.toSet().length);
  });
}
