import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/payment_method.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../widgets/payment_method_card.dart';

/// Écran d'abonnement fictif : rappelle le modèle économique du service
/// (100 à 200 FCFA/mois) et simule un paiement via Orange Money, Wave ou
/// Free Money. Aucune transaction réelle n'est effectuée.
class SubscriptionScreen extends ConsumerWidget {
  /// `true` lorsque l'écran est affiché de façon bloquante par [AppGate]
  /// (utilisateur connecté mais pas encore abonné) : pas de bouton retour,
  /// message d'intro adapté, et possibilité de se déconnecter.
  final bool mandatory;

  const SubscriptionScreen({super.key, this.mandatory = false});

  static final DateFormat _dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

  Future<void> _simulatePayment(
    BuildContext context,
    WidgetRef ref,
    String phone,
    PaymentMethod method,
  ) async {
    // Capturé avant tout `await` : dès que l'abonnement est activé,
    // AppGate peut remplacer SubscriptionScreen par la carte (cas
    // `mandatory`), ce qui invaliderait `context`. Le NavigatorState et son
    // propre BuildContext, eux, restent valides tant que l'app tourne.
    final navigator = Navigator.of(context);

    showDialog(
      context: navigator.context,
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

    // Simule la latence d'une confirmation de paiement mobile money : aucune
    // clé API marchand réelle n'est disponible pour Orange Money / Wave /
    // Free Money. En revanche, l'abonnement obtenu est bien sauvegardé sur
    // l'appareil (voir SubscriptionController.activate), pas seulement en
    // mémoire le temps de la session.
    await Future.delayed(const Duration(seconds: 2));

    final expiry = DateTime.now().add(const Duration(days: 30));
    await ref.read(subscriptionControllerProvider(phone).notifier).activate(expiry);

    navigator.pop(); // ferme le dialogue de chargement

    showDialog(
      // navigator.context reste valide après l'await : c'est le contexte du
      // NavigatorState racine, pas celui de ce widget (qui a pu être démonté).
      // ignore: use_build_context_synchronously
      context: navigator.context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.vertBaobab, size: 48),
        title: const Text('Paiement réussi'),
        content: Text(
          'Votre abonnement SunuBus est actif jusqu\'au '
          '${_safeFormat(expiry)}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => navigator.pop(),
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
    final phone = ref.watch(authControllerProvider).phone!;
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final expiry = ref.watch(subscriptionControllerProvider(phone)).value;
    final isActive = expiry != null && expiry.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !mandatory,
        title: const Text('Abonnement'),
        actions: mandatory
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Se déconnecter',
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (mandatory) ...[
            Text(
              'Un abonnement actif est nécessaire pour accéder au suivi des bus.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charbonChaud.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.terracotta, AppColors.ocreProfond],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
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
                color: AppColors.vertBaobab.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.vertBaobab),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.vertBaobab),
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
                  : () => _simulatePayment(context, ref, phone, selectedMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.charbonChaud.withValues(alpha: 0.5),
                ),
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
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.vertBaobab),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
