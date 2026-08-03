import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_bus/data/models/transport_mode.dart';
import 'package:sunu_bus/data/models/trip_preferences.dart';
import 'package:sunu_bus/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('renvoie les préférences par défaut si rien n\'a jamais été enregistré', () async {
    final service = PreferencesService();
    final prefs = await service.getPreferences('771112233');
    expect(prefs.preferredModes, TripPreferences.defaults.preferredModes);
    expect(prefs.comfortLevel, TripPreferences.defaults.comfortLevel);
  });

  test('persiste puis relit des préférences personnalisées', () async {
    final service = PreferencesService();
    const custom = TripPreferences(
      preferredModes: {TransportMode.taxi, TransportMode.tram},
      comfortLevel: ComfortLevel.confort,
      maxWalkMinutes: 5,
    );

    await service.savePreferences('771112233', custom);
    final reloaded = await service.getPreferences('771112233');

    expect(reloaded.preferredModes, custom.preferredModes);
    expect(reloaded.comfortLevel, ComfortLevel.confort);
    expect(reloaded.maxWalkMinutes, 5);
  });
}
