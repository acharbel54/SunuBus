import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_bus/data/models/emergency_contact.dart';
import 'package:sunu_bus/services/trip_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aucun contact d\'urgence tant que rien n\'est enregistré', () async {
    final service = TripSecurityService();
    expect(await service.getContact('771112233'), isNull);
  });

  test('enregistre, relit puis efface le contact d\'urgence', () async {
    final service = TripSecurityService();
    const contact = EmergencyContact(name: 'Awa Diop', phone: '770001122');

    await service.saveContact('771112233', contact);
    final reloaded = await service.getContact('771112233');
    expect(reloaded?.name, 'Awa Diop');
    expect(reloaded?.phone, '770001122');

    await service.clearContact('771112233');
    expect(await service.getContact('771112233'), isNull);
  });

  test('construit un message de partage de trajet lisible', () {
    final service = TripSecurityService();
    final message = service.buildTripShareMessage(
      originLabel: 'Plateau',
      destinationLabel: 'Guédiawaye',
      modeLabel: 'Bus',
      arrivalTime: DateTime(2026, 8, 3, 9, 45),
    );

    expect(message, contains('Plateau'));
    expect(message, contains('Guédiawaye'));
    expect(message, contains('Bus'));
    expect(message, contains('09:45'));
  });
}
