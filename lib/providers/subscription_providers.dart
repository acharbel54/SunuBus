import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payment_method.dart';
import '../services/subscription_service.dart';

/// Moyen de paiement actuellement sélectionné sur l'écran d'abonnement.
final selectedPaymentMethodProvider = StateProvider<PaymentMethod?>((ref) => null);

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) => SubscriptionService());

/// Charge puis persiste réellement la date d'expiration de l'abonnement de
/// l'utilisateur identifié par [phone] (`null` = pas encore abonné).
class SubscriptionController extends StateNotifier<AsyncValue<DateTime?>> {
  final SubscriptionService _service;
  final String phone;

  SubscriptionController(this._service, this.phone) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final expiry = await _service.getExpiry(phone);
    state = AsyncValue.data(expiry);
  }

  /// Active l'abonnement jusqu'à [expiry] et le sauvegarde sur l'appareil.
  Future<void> activate(DateTime expiry) async {
    await _service.setExpiry(phone, expiry);
    state = AsyncValue.data(expiry);
  }
}

/// Un contrôleur par numéro de téléphone connecté.
final subscriptionControllerProvider =
    StateNotifierProvider.family<SubscriptionController, AsyncValue<DateTime?>, String>(
  (ref, phone) => SubscriptionController(ref.watch(subscriptionServiceProvider), phone),
);
