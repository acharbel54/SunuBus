import 'package:flutter/foundation.dart';
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

  /// Plateformes où `flutter_local_notifications` dispose d'un canal natif.
  /// Sur le web (non supporté), les méthodes se neutralisent sans erreur.
  bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
      default:
        return false;
    }
  }

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
    // Plateforme sans support (ex: web) : on neutralise proprement plutôt
    // que de laisser les appels de plateforme échouer silencieusement.
    if (!isSupported) {
      _initialized = true;
      return;
    }
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
    if (!isSupported) return;
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
    if (!isSupported) return;
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Android 12+ : les alarmes exactes peuvent être désactivées par
    // l'utilisateur (`canScheduleExactAlarms`). On retombe alors en mode
    // inexact plutôt que de laisser le rappel échouer silencieusement.
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact = await android?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _details,
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> notifySosSent(String contactName) async {
    await init();
    if (!isSupported) return;
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
