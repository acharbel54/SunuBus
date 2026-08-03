import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sunu_bus/main.dart';
import 'package:sunu_bus/providers/auth_providers.dart';
import 'package:sunu_bus/providers/location_providers.dart';
import 'package:sunu_bus/providers/map_providers.dart';
import 'package:sunu_bus/providers/notification_providers.dart';
import 'package:sunu_bus/providers/subscription_providers.dart';
import 'package:sunu_bus/services/auth_service.dart';
import 'package:sunu_bus/services/geolocation_service.dart';
import 'package:sunu_bus/services/notification_service.dart';
import 'package:sunu_bus/services/subscription_service.dart';

/// Tuile blanche 256x256 minimale encodée en base64 (même fixture que les
/// tests internes de `flutter_map`) : évite toute requête réseau réelle vers
/// `tile.openstreetmap.org` pendant les tests widgets.
final _testTileBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEAAQMAAABmvDolAAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAANQTFRF////p8QbyAAAAB9JREFUeJztwQENAAAAwqD3T20ON6AAAAAAAAAAAL4NIQAAAfFnIe4AAAAASUVORK5CYII=',
);

class _TestTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_testTileBytes);
}

/// Numéro utilisé par défaut par [pumpAuthenticatedApp] dans les tests.
const testPhone = '771112233';

/// Session déjà ouverte, sans passer par le vrai `AuthService` (qui lit/écrit
/// `SharedPreferences`) : évite de dépendre du flux de connexion réel dans
/// les tests qui portent sur d'autres fonctionnalités.
class FakeAuthService extends AuthService {
  final String? phone;
  FakeAuthService({this.phone = testPhone});

  @override
  Future<String?> restoreSession() async => phone;
}

/// Abonnement toujours actif, pour atteindre directement [RootShell] dans
/// les tests sans repasser par l'écran d'abonnement.
class FakeSubscriptionService extends SubscriptionService {
  final DateTime? expiry;
  FakeSubscriptionService({DateTime? expiry})
      : expiry = expiry ?? DateTime.now().add(const Duration(days: 30));

  @override
  Future<DateTime?> getExpiry(String phone) async => expiry;

  @override
  Future<void> setExpiry(String phone, DateTime expiry) async {}
}

/// Position simulée (centre de Dakar), pour ne jamais dépendre d'un vrai
/// canal de plateforme `geolocator` (indisponible dans l'environnement de
/// test).
class FakeGeolocationService extends GeolocationService {
  @override
  Future<LocationResult> getCurrentPosition() async =>
      LocationSuccess(const LatLng(14.6937, -17.4441));
}

/// Notifications neutralisées : le plugin `flutter_local_notifications`
/// n'a pas d'implémentation de plateforme dans l'environnement de test.
class FakeNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> notifyBusApproaching({
    required String lineLabel,
    required String stopName,
    required int etaMinutes,
  }) async {}

  @override
  Future<void> scheduleTripReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {}

  @override
  Future<void> notifySosSent(String contactName) async {}

  @override
  Future<void> cancelReminder(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Monte l'application complète avec une session authentifiée et un
/// abonnement actif déjà en place, jusqu'à ce que [RootShell] (carte +
/// barre de navigation) soit affiché.
Future<void> pumpAuthenticatedApp(WidgetTester tester, {String phone = testPhone}) async {
  SharedPreferences.setMockInitialValues({});
  // Les écrans d'itinéraires/réservations formatent des dates en français
  // (`DateFormat(..., 'fr_FR')`) ; `main()` charge ces données au démarrage
  // réel de l'app, mais les tests widgets sautent `main()` et doivent le
  // faire eux-mêmes avant de peindre un écran qui en dépend.
  await initializeDateFormatting('fr_FR', null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(phone: phone)),
        subscriptionServiceProvider.overrideWithValue(FakeSubscriptionService()),
        geolocationServiceProvider.overrideWithValue(FakeGeolocationService()),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        mapTileProviderProvider.overrideWithValue(_TestTileProvider()),
      ],
      child: const SunuBusApp(),
    ),
  );

  // N'utilise pas `pumpAndSettle` : le pouls "en direct" du bandeau de la
  // carte (`_LivePulseDot`) tourne en boucle infinie et empêcherait l'app de
  // jamais "settle". On avance plutôt par petits pas, juste assez pour
  // laisser les futures (restauration de session, abonnement) se résoudre,
  // sans jamais atteindre les 2,5s du tick de `BusSimulationService`.
  await settle(tester);
}

/// Avance le temps par petits pas plutôt que `pumpAndSettle` (voir
/// commentaire ci-dessus) : à utiliser après toute interaction (tap,
/// navigation, saisie) une fois [pumpAuthenticatedApp] appelé.
Future<void> settle(WidgetTester tester, {int times = 8}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
