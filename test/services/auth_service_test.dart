import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_bus/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('inscription : normalise le numéro et ouvre une session', () async {
    final service = AuthService();
    final phone = await service.register('77 123 45 67', 'motdepasse');

    expect(phone, '771234567');
    expect(await service.restoreSession(), '771234567');
  });

  test('inscription : refuse un numéro déjà utilisé', () async {
    final service = AuthService();
    await service.register('771234567', 'motdepasse');

    expect(
      () => service.register('77 123 45 67', 'autre'),
      throwsA(isA<AuthException>()),
    );
  });

  test('connexion : refuse un mot de passe incorrect', () async {
    final service = AuthService();
    await service.register('771234567', 'motdepasse');

    expect(
      () => service.login('771234567', 'mauvais'),
      throwsA(isA<AuthException>()),
    );
  });

  test('connexion : refuse un compte inexistant', () async {
    final service = AuthService();
    expect(
      () => service.login('770000000', 'motdepasse'),
      throwsA(isA<AuthException>()),
    );
  });

  test('connexion : ouvre une session sur bons identifiants', () async {
    final service = AuthService();
    await service.register('771234567', 'motdepasse');
    await service.logout();
    expect(await service.restoreSession(), isNull);

    final phone = await service.login('771234567', 'motdepasse');
    expect(phone, '771234567');
    expect(await service.restoreSession(), '771234567');
  });

  test('déconnexion : ferme la session', () async {
    final service = AuthService();
    await service.register('771234567', 'motdepasse');
    await service.logout();

    expect(await service.restoreSession(), isNull);
  });

  test('ne stocke jamais le mot de passe en clair (hash + sel)', () async {
    final service = AuthService();
    await service.register('771234567', 'motdepasse');

    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString('sunubus_users')!;

    expect(rawUsers.contains('motdepasse'), isFalse);
    // Le sel et le hash SHA-256 sont bien présents.
    expect(rawUsers.contains('salt'), isTrue);
    expect(rawUsers.contains('hash'), isTrue);
  });
}
