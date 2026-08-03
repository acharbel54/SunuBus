import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// État d'authentification : [isLoading] tant que la session existante n'a
/// pas encore été relue depuis le stockage de l'appareil ; [phone] non nul
/// une fois l'utilisateur connecté.
class AuthState {
  final bool isLoading;
  final String? phone;

  const AuthState({required this.isLoading, this.phone});

  bool get isAuthenticated => phone != null;
}

/// Pilote l'inscription, la connexion et la déconnexion via [AuthService],
/// et restaure automatiquement la session au démarrage de l'application.
class AuthController extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthController(this._service) : super(const AuthState(isLoading: true)) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final phone = await _service.restoreSession();
    state = AuthState(isLoading: false, phone: phone);
  }

  Future<void> register(String phone, String password) async {
    final normalized = await _service.register(phone, password);
    state = AuthState(isLoading: false, phone: normalized);
  }

  Future<void> login(String phone, String password) async {
    final normalized = await _service.login(phone, password);
    state = AuthState(isLoading: false, phone: normalized);
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(isLoading: false, phone: null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);
