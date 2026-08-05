import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bus.dart';
import 'bus_simulation_engine.dart';

/// Service de simulation temps réel des bus.
///
/// Toute la logique de mouvement (interpolation, ETA, remplissage) vit dans
/// [BusSimulationEngine] (classe pure, testable). Ce service ne fait que :
///   - faire tourner le [Timer] qui déclenche une avancée toutes les ~2,5 s,
///   - exposer la liste des bus via [StateNotifier] pour que l'UI se
///     reconstruise automatiquement à chaque mise à jour grâce à Riverpod.
class BusSimulationService extends StateNotifier<List<Bus>> {
  BusSimulationService({int busesPerLine = 3, Random? random})
      : _engine = BusSimulationEngine(
          tickInterval: _tickInterval,
          random: random,
        ),
        super(const []) {
    state = _engine.initializeBuses(busesPerLine: busesPerLine);
    _startTimer();
  }

  /// Intervalle de rafraîchissement de la simulation (entre 2 et 3 secondes).
  static const Duration _tickInterval = Duration(milliseconds: 2500);

  final BusSimulationEngine _engine;
  late Timer _timer;

  void _startTimer() => _timer = Timer.periodic(_tickInterval, (_) => _tick());

  void _tick() => state = _engine.advance(state);

  /// Coupe le timer : à appeler quand l'app passe en arrière-plan pour ne
  /// pas gaspiller la batterie à simuler des bus que personne ne regarde.
  void pause() => _timer.cancel();

  /// Relance le timer après une [pause]. Sans effet s'il tourne déjà.
  void resume() {
    if (_timer.isActive) return;
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
