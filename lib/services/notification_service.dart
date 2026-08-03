import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales uniquement (arrivée de bus, rappel de trajet).
///
/// Point d'intégration API réelle : pour des alertes fiables même app
/// fermée (ex: "ton bus arrive dans 3 min" en arrière-plan prolongé), il
/// faudrait relayer ces événements via un service de notifications push
/// distant (ex: Firebase Cloud Messaging) déclenché côté serveur.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'sunubus_alerts',
    'Alertes SunuBus',
    channelDescription: "Arrivée de bus, rappels de trajet et alertes de sécurité",
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir SunuBus'),
    );
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> notifyBusApproaching({
    required String lineLabel,
    required String stopName,
    required int etaMinutes,
  }) async {
    await init();
    await _plugin.show(
      lineLabel.hashCode,
      '$lineLabel arrive bientôt',
      'Dans environ $etaMinutes min à $stopName',
      _details,
    );
  }

  Future<void> scheduleTripReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await init();
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> notifySosSent(String contactName) async {
    await init();
    await _plugin.show(
      'sos-$contactName'.hashCode,
      'Alerte envoyée',
      'Votre contact $contactName a été alerté (simulation).',
      _details,
    );
  }

  Future<void> cancelReminder(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
