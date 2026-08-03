import 'package:flutter_test/flutter_test.dart';
import 'package:sunu_bus/services/schedule_service.dart';

void main() {
  final service = ScheduleService();

  test('renvoie des départs triés par heure croissante pour un arrêt desservi', () {
    final now = DateTime(2026, 8, 3, 8, 0);
    final departures = service.departuresForStop('Plateau', now: now);

    expect(departures, isNotEmpty);
    for (var i = 1; i < departures.length; i++) {
      expect(
        departures[i].scheduledTime.isAfter(departures[i - 1].scheduledTime) ||
            departures[i].scheduledTime.isAtSameMomentAs(departures[i - 1].scheduledTime),
        isTrue,
      );
    }
    for (final departure in departures) {
      expect(departure.scheduledTime.isAfter(now), isTrue);
    }
  });

  test('ne renvoie rien pour un arrêt inconnu', () {
    final departures = service.departuresForStop('Arrêt inexistant');
    expect(departures, isEmpty);
  });
}
