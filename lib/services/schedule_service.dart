import 'dart:math';

import '../data/datasources/dakar_network.dart';
import '../data/datasources/multimodal_network.dart';
import '../data/models/bus_line.dart';
import '../data/models/schedule_departure.dart';

/// Génère l'horaire "officiel" (grille théorique à intervalle régulier) des
/// prochains passages à un arrêt donné, toutes lignes confondues.
///
/// Point d'intégration API réelle : en production, remplacer par un appel à
/// un flux GTFS statique (horaires officiels de l'exploitant) plutôt qu'une
/// grille générée localement.
class ScheduleService {
  static const List<BusLine> _allLines = [
    ...DakarNetwork.lines,
    ...MultimodalNetwork.navetteLines,
    ...MultimodalNetwork.tramLines,
  ];

  List<ScheduleDeparture> departuresForStop(String stopName, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final servingLines = _allLines.where((l) => l.stops.any((s) => s.name == stopName));

    final departures = <ScheduleDeparture>[];
    for (final line in servingLines) {
      // Graine déterministe par ligne : intervalle stable d'un appel à l'autre.
      final random = Random(line.id.hashCode);
      final intervalMinutes = 8 + random.nextInt(10); // 8 à 17 minutes

      var next = _roundUpToInterval(currentTime, intervalMinutes);
      for (int i = 0; i < 6; i++) {
        departures.add(ScheduleDeparture(
          lineId: line.id,
          lineNumber: line.number,
          scheduledTime: next,
          isRealtime: i == 0,
        ));
        next = next.add(Duration(minutes: intervalMinutes));
      }
    }

    departures.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return departures;
  }

  DateTime _roundUpToInterval(DateTime time, int intervalMinutes) {
    final minutesSinceMidnight = time.hour * 60 + time.minute;
    final remainder = minutesSinceMidnight % intervalMinutes;
    final minutesToAdd = remainder == 0 ? intervalMinutes : intervalMinutes - remainder;
    return DateTime(time.year, time.month, time.day, time.hour, time.minute)
        .add(Duration(minutes: minutesToAdd));
  }
}
