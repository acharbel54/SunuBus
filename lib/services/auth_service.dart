import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Erreur d'authentification (numéro déjà utilisé, compte introuvable,
/// mot de passe incorrect...), avec un message prêt à afficher à l'écran.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Gère la création de compte et la connexion des utilisateurs.
///
/// Les comptes sont stockés localement sur l'appareil (l'application n'a
/// pas de backend). Les mots de passe ne sont jamais conservés en clair :
/// seuls un sel aléatoire et le hash SHA-256 de `sel:motDePasse` sont
/// sauvegardés. La session (numéro connecté) est elle aussi persistée afin
/// que l'utilisateur reste connecté d'un lancement à l'autre.
class AuthService {
  static const _usersKey = 'sunubus_users';
  static const _sessionKey = 'sunubus_session_phone';

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\s+'), '');

  /// Crée un compte pour [phone] et ouvre une session. Lève [AuthException]
  /// si un compte existe déjà avec ce numéro. Retourne le numéro normalisé.
  Future<String> register(String phone, String password) async {
    final normalized = _normalizePhone(phone);
    final users = await _loadUsers();
    if (users.containsKey(normalized)) {
      throw const AuthException('Un compte existe déjà avec ce numéro.');
    }
    final salt = _generateSalt();
    users[normalized] = {'salt': salt, 'hash': _hash(password, salt)};
    await _saveUsers(users);
    await _setSession(normalized);
    return normalized;
  }

  /// Vérifie les identifiants et ouvre une session si valides. Lève
  /// [AuthException] si le compte n'existe pas ou si le mot de passe est
  /// incorrect. Retourne le numéro normalisé.
  Future<String> login(String phone, String password) async {
    final normalized = _normalizePhone(phone);
    final users = await _loadUsers();
    final record = users[normalized] as Map<String, dynamic>?;
    if (record == null) {
      throw const AuthException('Aucun compte trouvé pour ce numéro.');
    }
    final expectedHash = _hash(password, record['salt'] as String);
    if (expectedHash != record['hash']) {
      throw const AuthException('Mot de passe incorrect.');
    }
    await _setSession(normalized);
    return normalized;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Numéro de la session ouverte, ou `null` si personne n'est connecté.
  Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> _setSession(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, phone);
  }
}
