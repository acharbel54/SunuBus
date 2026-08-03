import 'transport_mode.dart';

enum BookingStatus { upcoming, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming:
        return 'À venir';
      case BookingStatus.completed:
        return 'Terminé';
      case BookingStatus.cancelled:
        return 'Annulé';
    }
  }
}

/// Une réservation de trajet, créée depuis un [Itinerary] choisi par
/// l'utilisateur. Persistée localement par numéro de téléphone
/// (voir `BookingService`) — aucun backend de réservation réel.
class Booking {
  final String id;
  final String originLabel;
  final String destinationLabel;

  /// Mode principal de l'itinéraire réservé (le premier tronçon motorisé).
  final TransportMode primaryMode;

  final DateTime scheduledAt;
  final double priceFcfa;
  final int durationMinutes;
  final BookingStatus status;
  final bool reminderEnabled;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.originLabel,
    required this.destinationLabel,
    required this.primaryMode,
    required this.scheduledAt,
    required this.priceFcfa,
    required this.durationMinutes,
    required this.status,
    required this.createdAt,
    this.reminderEnabled = false,
  });

  Booking copyWith({BookingStatus? status, bool? reminderEnabled}) {
    return Booking(
      id: id,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      primaryMode: primaryMode,
      scheduledAt: scheduledAt,
      priceFcfa: priceFcfa,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      createdAt: createdAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originLabel': originLabel,
        'destinationLabel': destinationLabel,
        'primaryMode': primaryMode.name,
        'scheduledAt': scheduledAt.toIso8601String(),
        'priceFcfa': priceFcfa,
        'durationMinutes': durationMinutes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'reminderEnabled': reminderEnabled,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        originLabel: json['originLabel'] as String,
        destinationLabel: json['destinationLabel'] as String,
        primaryMode: TransportMode.values.byName(json['primaryMode'] as String),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        priceFcfa: (json['priceFcfa'] as num).toDouble(),
        durationMinutes: json['durationMinutes'] as int,
        status: BookingStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      );
}
