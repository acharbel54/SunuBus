import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/root_shell.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'providers/auth_providers.dart';
import 'providers/subscription_providers.dart';

/// Point d'entrée du parcours utilisateur : détermine l'écran à afficher
/// selon l'état (réel, persisté sur l'appareil) de connexion et
/// d'abonnement.
///
/// - Session en cours de restauration -> [_SplashScreen]
/// - Pas connecté -> [LoginScreen]
/// - Connecté mais pas abonné (ou abonnement expiré) -> [SubscriptionScreen],
///   affiché de façon bloquante : impossible d'accéder à la carte sans payer.
/// - Connecté et abonné -> [RootShell]
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading) {
      return const _SplashScreen();
    }
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final subscription = ref.watch(subscriptionControllerProvider(auth.phone!));

    return subscription.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const SubscriptionScreen(mandatory: true),
      data: (expiry) {
        final isSubscribed = expiry != null && expiry.isAfter(DateTime.now());
        return isSubscribed ? const RootShell() : const SubscriptionScreen(mandatory: true);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.sableClair,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.terracotta),
      ),
    );
  }
}
