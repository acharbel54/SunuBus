import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/datasources/dakar_network.dart';
import '../data/models/bus.dart';
import '../data/models/bus_line.dart';
import '../data/models/occupancy_level.dart';

/// Service de simulation temps réel des bus.
///
/// En l'absence de capteurs GPS physiques, ce service fait office de
/// "serveur de télémétrie" : il fait avancer chaque bus le long du trajet
/// de sa ligne, arrêt après arrêt, en recalculant à chaque tick :
///   - sa position GPS interpolée,
///   - le prochain arrêt,
///   - le temps estimé avant d'y arriver (ETA),
///   - un niveau de remplissage qui évolue occasionnellement.
///
/// Il expose son état via [StateNotifier] (`List<Bus>`), ce qui permet à
/// l'UI de se reconstruire automatiquement à chaque mise à jour grâce à
/// Riverpod.
class BusSimulationService extends StateNotifier<List<Bus>> {
  BusSimulationService({int busesPerLine = 3})
      : _random = Random(),
        super(const []) {
    _initializeBuses(busesPerLine);
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  /// Intervalle de rafraîchissement de la simulation (entre 2 et 3 secondes).
  static const Duration _tickInterval = Duration(milliseconds: 2500);

  final Random _random;
  final Distance _distanceCalculator = const Distance();
  late final Timer _timer;

  /// Vitesse (en m/s) attribuée à chaque bus, générée une fois à
  /// l'initialisation puis conservée pour un mouvement cohérent.
  /// (~18 à 34 km/h, réaliste pour un trajet urbain avec arrêts fréquents)
  final Map<String, double> _busSpeeds = {};

  void _initializeBuses(int busesPerLine) {
    final List<Bus> initialBuses = [];

    for (final line in DakarNetwork.lines) {
      for (int i = 0; i < busesPerLine; i++) {
        final busId = '${line.id}-bus-${i + 1}';

        // Répartit les bus à des positions de départ variées sur la ligne
        // pour que la simulation semble déjà "en cours" au démarrage.
        final segmentIndex = _random.nextInt(line.stops.length - 1);
        final forward = _random.nextBool();
        final segmentProgress = _random.nextDouble();

        _busSpeeds[busId] = 5.0 + _random.nextDouble() * 4.5; // 5 à 9.5 m/s

        final position = _interpolate(
          line.stops[segmentIndex].position,
          line.stops[_nextIndex(segmentIndex, forward, line)].position,
          segmentProgress,
        );

        initialBuses.add(Bus(
          id: busId,
          lineId: line.id,
          position: position,
          segmentIndex: segmentIndex,
          forward: forward,
          segmentProgress: segmentProgress,
          nextStopName: line.stops[_nextIndex(segmentIndex, forward, line)].name,
          etaMinutes: 1 + _random.nextInt(8),
          occupancy: OccupancyLevel.values[_random.nextInt(OccupancyLevel.values.length)],
        ));
      }
    }

    state = initialBuses;
  }

  void _tick() {
    state = [for (final bus in state) _advanceBus(bus)];
  }

  Bus _advanceBus(Bus bus) {
    final line = DakarNetwork.lineById(bus.lineId);
    final speed = _busSpeeds[bus.id]!;
    final dtSeconds = _tickInterval.inMilliseconds / 1000.0;
    final distanceTravelled = speed * dtSeconds;

    int segmentIndex = bus.segmentIndex;
    bool forward = bus.forward;
    double segmentProgress = bus.segmentProgress;

    // Autorise à franchir plusieurs arrêts en un seul tick si la vitesse
    // le permet (segments courts), via une boucle de "report" de distance.
    double remainingDistance = distanceTravelled;

    while (true) {
      final nextIdx = _nextIndex(segmentIndex, forward, line);
      final segStart = line.stops[segmentIndex].position;
      final segEnd = line.stops[nextIdx].position;
      final segLengthMeters = _distanceCalculator.as(LengthUnit.Meter, segStart, segEnd);
      final remainingOnSegment = segLengthMeters * (1 - segmentProgress);

      if (remainingDistance < remainingOnSegment) {
        segmentProgress += remainingDistance / segLengthMeters;
        remainingDistance = 0;
        break;
      }

      // Le bus atteint (ou dépasse) l'arrêt suivant : on avance de segment.
      remainingDistance -= remainingOnSegment;
      segmentIndex = nextIdx;
      segmentProgress = 0;

      // Rebrousse chemin si on vient d'atteindre un terminus.
      if (forward && segmentIndex >= line.stops.length - 1) {
        forward = false;
      } else if (!forward && segmentIndex <= 0) {
        forward = true;
      }
    }

    final nextIdx = _nextIndex(segmentIndex, forward, line);
    final segStart = line.stops[segmentIndex].position;
    final segEnd = line.stops[nextIdx].position;
    final newPosition = _interpolate(segStart, segEnd, segmentProgress);

    final segLengthMeters = _distanceCalculator.as(LengthUnit.Meter, segStart, segEnd);
    final remainingMeters = segLengthMeters * (1 - segmentProgress);
    final etaMinutes = max(1, (remainingMeters / speed / 60).ceil());

    // Le niveau de remplissage évolue occasionnellement pour rester réaliste
    // (un bus ne se vide/remplit pas totalement toutes les 2,5 secondes).
    OccupancyLevel occupancy = bus.occupancy;
    if (_random.nextDouble() < 0.08) {
      occupancy = OccupancyLevel.values[_random.nextInt(OccupancyLevel.values.length)];
    }

    return bus.copyWith(
      position: newPosition,
      segmentIndex: segmentIndex,
      forward: forward,
      segmentProgress: segmentProgress,
      nextStopName: line.stops[nextIdx].name,
      etaMinutes: etaMinutes,
      occupancy: occupancy,
    );
  }

  int _nextIndex(int currentIndex, bool forward, BusLine line) {
    final maxIndex = line.stops.length - 1;
    if (forward) {
      return currentIndex + 1 > maxIndex ? maxIndex : currentIndex + 1;
    }
    return currentIndex - 1 < 0 ? 0 : currentIndex - 1;
  }

  LatLng _interpolate(LatLng a, LatLng b, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * clampedT,
      a.longitude + (b.longitude - a.longitude) * clampedT,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
