import 'package:shared_preferences/shared_preferences.dart';

/// Persiste réellement la date d'expiration de l'abonnement de chaque
/// utilisateur (identifié par son numéro de téléphone) sur l'appareil.
///
/// Aucune transaction d'argent réelle n'a lieu (aucune clé API marchand
/// Orange Money / Wave / Free Money) : seul l'état "abonné jusqu'au..." est
/// sauvegardé de façon durable, contrairement à un simple état en mémoire
/// qui se réinitialiserait à chaque relance de l'application.
class SubscriptionService {
  String _key(String phone) => 'sunubus_subscription_$phone';

  Future<DateTime?> getExpiry(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_key(phone));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setExpiry(String phone, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(phone), expiry.millisecondsSinceEpoch);
  }
}
