import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payment_method.dart';

/// Moyen de paiement actuellement sélectionné sur l'écran d'abonnement.
final selectedPaymentMethodProvider = StateProvider<PaymentMethod?>((ref) => null);

/// Date d'expiration de l'abonnement simulé. `null` = pas encore abonné.
final subscriptionExpiryProvider = StateProvider<DateTime?>((ref) => null);
