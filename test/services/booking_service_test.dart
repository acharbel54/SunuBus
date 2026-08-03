import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_bus/data/models/booking.dart';
import 'package:sunu_bus/data/models/transport_mode.dart';
import 'package:sunu_bus/services/booking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aucune réservation pour un utilisateur qui n\'en a jamais fait', () async {
    final service = BookingService();
    expect(await service.getBookings('771112233'), isEmpty);
  });

  test('persiste puis relit les réservations, isolées par numéro de téléphone', () async {
    final service = BookingService();
    final booking = Booking(
      id: '1',
      originLabel: 'Plateau',
      destinationLabel: 'Guédiawaye',
      primaryMode: TransportMode.bus,
      scheduledAt: DateTime(2026, 8, 10, 9, 0),
      priceFcfa: 250,
      durationMinutes: 42,
      status: BookingStatus.upcoming,
      createdAt: DateTime(2026, 8, 3),
    );

    await service.saveBookings('771112233', [booking]);

    final reloaded = await service.getBookings('771112233');
    expect(reloaded, hasLength(1));
    expect(reloaded.single.originLabel, 'Plateau');
    expect(reloaded.single.primaryMode, TransportMode.bus);
    expect(reloaded.single.status, BookingStatus.upcoming);

    // Un autre numéro de téléphone ne doit rien voir de ces réservations.
    expect(await service.getBookings('770000000'), isEmpty);
  });
}
