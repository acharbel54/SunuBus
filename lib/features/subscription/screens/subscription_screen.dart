import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/payment_method.dart';
import '../../../providers/subscription_providers.dart';
import '../widgets/payment_method_card.dart';

/// Écran d'abonnement fictif : rappelle le modèle économique du service
/// (100 à 200 FCFA/mois) et simule un paiement via Orange Money, Wave ou
/// Free Money. Aucune transaction réelle n'est effectuée.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static final DateFormat _dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

  Future<void> _simulatePayment(BuildContext context, WidgetRef ref, PaymentMethod method) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text('Paiement via ${method.label} en cours...')),
          ],
        ),
      ),
    );

    // Simule la latence d'une confirmation de paiement mobile money.
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    Navigator.of(context).pop(); // ferme le dialogue de chargement

    final expiry = DateTime.now().add(const Duration(days: 30));
    ref.read(subscriptionExpiryProvider.notifier).state = expiry;

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
        title: const Text('Paiement réussi'),
        content: Text(
          'Votre abonnement SunuBus est actif jusqu\'au '
          '${_safeFormat(expiry)}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFormat(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (_) {
      // Repli si les données de locale 'fr_FR' ne sont pas initialisées.
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final expiry = ref.watch(subscriptionExpiryProvider);
    final isActive = expiry != null && expiry.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00853F), Color(0xFF00A651)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À partir de 100 FCFA / mois',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Suivi en temps réel illimité de tous les bus (Tata, Dem Dikk) à Dakar.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Abonnement actif jusqu\'au ${_safeFormat(expiry)}'),
                  ),
                ],
              ),
            ),
          if (isActive) const SizedBox(height: 24),

          Text('Avantages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _FeatureRow(text: 'Position des bus actualisée en temps réel'),
          const _FeatureRow(text: 'Alertes d\'arrivée à votre arrêt'),
          const _FeatureRow(text: 'Toutes les lignes Tata et Dem Dikk incluses'),
          const _FeatureRow(text: 'Sans publicité'),

          const SizedBox(height: 28),
          Text(
            'Choisissez votre moyen de paiement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final method in PaymentMethod.values) ...[
            PaymentMethodCard(
              method: method,
              selected: selectedMethod == method,
              onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = method,
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selectedMethod == null
                  ? null
                  : () => _simulatePayment(context, ref, selectedMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00853F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isActive ? 'Renouveler pour 150 FCFA' : 'Payer maintenant · 150 FCFA',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ceci est une simulation à des fins de démonstration. Aucun paiement réel n\'est effectué.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF00853F)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
