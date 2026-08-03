import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/booking.dart';
import '../data/models/transport_mode.dart';
import '../services/booking_service.dart';

final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());

/// Réservations de l'utilisateur connecté, persistées sur l'appareil.
class BookingController extends StateNotifier<List<Booking>> {
  final BookingService _service;
  final String phone;

  BookingController(this._service, this.phone) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getBookings(phone);
  }

  Future<Booking> create({
    required String originLabel,
    required String destinationLabel,
    required TransportMode primaryMode,
    required DateTime scheduledAt,
    required double priceFcfa,
    required int durationMinutes,
  }) async {
    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      primaryMode: primaryMode,
      scheduledAt: scheduledAt,
      priceFcfa: priceFcfa,
      durationMinutes: durationMinutes,
      status: BookingStatus.upcoming,
      createdAt: DateTime.now(),
    );
    state = [...state, booking];
    await _service.saveBookings(phone, state);
    return booking;
  }

  Future<void> cancel(String id) async {
    state = [
      for (final b in state) if (b.id == id) b.copyWith(status: BookingStatus.cancelled) else b,
    ];
    await _service.saveBookings(phone, state);
  }

  Future<void> setReminder(String id, bool enabled) async {
    state = [
      for (final b in state) if (b.id == id) b.copyWith(reminderEnabled: enabled) else b,
    ];
    await _service.saveBookings(phone, state);
  }
}

final bookingControllerProvider =
    StateNotifierProvider.family<BookingController, List<Booking>, String>(
  (ref, phone) => BookingController(ref.watch(bookingServiceProvider), phone),
);
