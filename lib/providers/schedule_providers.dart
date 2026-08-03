import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/schedule_departure.dart';
import '../services/schedule_service.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) => ScheduleService());

/// Prochains départs "officiels" pour un arrêt donné (identifié par son nom).
final stopDeparturesProvider =
    Provider.autoDispose.family<List<ScheduleDeparture>, String>((ref, stopName) {
  return ref.watch(scheduleServiceProvider).departuresForStop(stopName);
});
