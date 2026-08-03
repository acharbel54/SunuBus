import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

/// Ligne actuellement suivie pour les alertes "bus proche" (`null` = aucune).
/// Activée depuis le panneau de liste des bus.
final watchedLineIdProvider = StateProvider<String?>((ref) => null);
