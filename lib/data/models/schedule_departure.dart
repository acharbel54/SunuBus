/// Un départ "officiel" d'une ligne à un arrêt donné, tel qu'annoncé par
/// l'horaire théorique — éventuellement recoupé avec la position temps réel
/// d'un bus simulé lorsque `isRealtime` est vrai.
class ScheduleDeparture {
  final String lineId;
  final String lineNumber;
  final DateTime scheduledTime;

  /// Vrai lorsque cet horaire a été recoupé avec la position temps réel d'un
  /// bus en circulation (plutôt qu'une simple grille théorique).
  final bool isRealtime;

  const ScheduleDeparture({
    required this.lineId,
    required this.lineNumber,
    required this.scheduledTime,
    this.isRealtime = false,
  });
}
