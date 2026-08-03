import 'transport_mode.dart';

enum ComfortLevel { economique, standard, confort }

extension ComfortLevelX on ComfortLevel {
  String get label {
    switch (this) {
      case ComfortLevel.economique:
        return 'Économique';
      case ComfortLevel.standard:
        return 'Standard';
      case ComfortLevel.confort:
        return 'Confort';
    }
  }
}

/// Préférences de recherche d'itinéraire de l'utilisateur, persistées par
/// numéro de téléphone (voir `PreferencesService`).
class TripPreferences {
  final Set<TransportMode> preferredModes;
  final ComfortLevel comfortLevel;
  final int maxWalkMinutes;

  const TripPreferences({
    required this.preferredModes,
    required this.comfortLevel,
    required this.maxWalkMinutes,
  });

  static const TripPreferences defaults = TripPreferences(
    preferredModes: {
      TransportMode.bus,
      TransportMode.tram,
      TransportMode.taxi,
      TransportMode.navette,
    },
    comfortLevel: ComfortLevel.standard,
    maxWalkMinutes: 15,
  );

  TripPreferences copyWith({
    Set<TransportMode>? preferredModes,
    ComfortLevel? comfortLevel,
    int? maxWalkMinutes,
  }) {
    return TripPreferences(
      preferredModes: preferredModes ?? this.preferredModes,
      comfortLevel: comfortLevel ?? this.comfortLevel,
      maxWalkMinutes: maxWalkMinutes ?? this.maxWalkMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferredModes': preferredModes.map((m) => m.name).toList(),
        'comfortLevel': comfortLevel.name,
        'maxWalkMinutes': maxWalkMinutes,
      };

  factory TripPreferences.fromJson(Map<String, dynamic> json) => TripPreferences(
        preferredModes: (json['preferredModes'] as List)
            .map((m) => TransportMode.values.byName(m as String))
            .toSet(),
        comfortLevel: ComfortLevel.values.byName(json['comfortLevel'] as String),
        maxWalkMinutes: json['maxWalkMinutes'] as int,
      );
}
