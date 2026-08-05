import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sunu_bus/data/models/bus_line.dart';
import 'package:sunu_bus/data/models/bus_stop.dart';
import 'package:sunu_bus/services/bus_simulation_engine.dart';

/// Ligne synthétique courte (3 arrêts espacés d'environ 0,01° de latitude,
/// soit ~1,1 km) : suffisante pour tester mouvement et rebroussement sans
/// dépendre des données réelles de Dakar.
const _tinyLine = BusLine(
  id: 'tiny',
  number: 'Ligne Test',
  operatorName: 'Test',
  color: Colors.black,
  stops: [
    BusStop(id: 'a', name: 'A', position: LatLng(14.70, -17.45)),
    BusStop(id: 'b', name: 'B', position: LatLng(14.71, -17.45)),
    BusStop(id: 'c', name: 'C', position: LatLng(14.72, -17.45)),
  ],
);

/// Moteur déterministe : Random seedé, tick long pour que les bus avancent
/// nettement à chaque appel de `advance`.
BusSimulationEngine _engine({Duration tick = const Duration(seconds: 10)}) {
  return BusSimulationEngine(
    tickInterval: tick,
    lines: [_tinyLine],
    random: Random(42),
  );
}

void main() {
  test('initialise le nombre de bus demandé par ligne, avec des vitesses', () {
    final engine = _engine();
    final buses = engine.initializeBuses(busesPerLine: 3);

    expect(buses, hasLength(3));
    for (final bus in buses) {
      expect(bus.lineId, 'tiny');
      expect(bus.segmentIndex, inInclusiveRange(0, _tinyLine.stops.length - 2));
      expect(bus.etaMinutes, greaterThanOrEqualTo(1));
      expect(bus.occupancy, isNotNull);
    }
  });

  test('fait avancer un bus le long de son segment sans sortir des bornes', () {
    final engine = _engine();
    final buses = engine.initializeBuses(busesPerLine: 2);

    var advanced = buses;
    for (var i = 0; i < 50; i++) {
      advanced = engine.advance(advanced);
      for (final bus in advanced) {
        // L'index de segment reste toujours dans les bornes de la ligne.
        expect(bus.segmentIndex, inInclusiveRange(0, _tinyLine.stops.length - 1));
        expect(bus.etaMinutes, greaterThanOrEqualTo(1));
      }
    }
  });

  test('rebrousse chemin une fois le terminus atteint', () {
    final engine = _engine();
    final buses = engine.initializeBuses(busesPerLine: 1);
    final start = buses.single;

    // Place le bus à la toute fin de la ligne, sens aller, quasi arrivé.
    final nearTerminus = start.copyWith(
      segmentIndex: _tinyLine.stops.length - 2,
      forward: true,
      segmentProgress: 0.999,
    );

    final advanced = engine.advance([nearTerminus]).single;

    // Il a atteint le terminus et doit repartir dans l'autre sens.
    expect(advanced.segmentIndex, _tinyLine.stops.length - 1);
    expect(advanced.forward, isFalse);
    expect(advanced.nextStopName, _tinyLine.stops[_tinyLine.stops.length - 2].name);
  });

  test('le même bus conserve sa vitesse d\'un tick à l\'autre', () {
    final engine = _engine();
    final buses = engine.initializeBuses(busesPerLine: 1);
    final start = buses.single;

    final afterOne = engine.advance([start]).single;
    final afterTwo = engine.advance([afterOne]).single;

    // Aucune erreur de lookup de vitesse : le bus avance toujours.
    expect(afterTwo.position, isNot(equals(start.position)));
  });

  test('le rebroussement au premier arrêt remet le bus dans le sens aller', () {
    final engine = _engine();
    final buses = engine.initializeBuses(busesPerLine: 1);
    final start = buses.single;

    // Place le bus quasi arrivé au premier arrêt (indice 0) en sens retour.
    final nearStart = start.copyWith(
      segmentIndex: 1,
      forward: false,
      segmentProgress: 0.999,
    );

    final advanced = engine.advance([nearStart]).single;

    expect(advanced.segmentIndex, 0);
    expect(advanced.forward, isTrue);
    expect(advanced.nextStopName, _tinyLine.stops[1].name);
  });
}
