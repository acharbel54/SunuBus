import 'package:flutter/material.dart';

/// Moyens de paiement mobile courants au Sénégal, proposés pour la
/// simulation d'abonnement (aucune transaction réelle n'est effectuée).
enum PaymentMethod { orangeMoney, wave, freeMoney }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.freeMoney:
        return 'Free Money';
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return const Color(0xFFFF6600);
      case PaymentMethod.wave:
        return const Color(0xFF1DC8E5);
      case PaymentMethod.freeMoney:
        return const Color(0xFFE30613);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return Icons.account_balance_wallet;
      case PaymentMethod.wave:
        return Icons.waves;
      case PaymentMethod.freeMoney:
        return Icons.payments;
    }
  }
}
