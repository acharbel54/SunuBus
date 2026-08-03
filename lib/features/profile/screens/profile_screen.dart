import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_providers.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../trip_planner/widgets/transport_mode_filter_sheet.dart';
import 'trip_security_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(authControllerProvider).phone!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sableCarte,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.terracotta,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Compte SunuBus', style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.charbonChaud.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProfileTile(
              icon: Icons.tune,
              title: 'Préférences de trajet',
              subtitle: 'Modes de transport, confort, marche max',
              onTap: () => showTransportModeFilterSheet(context, phone: phone),
            ),
            _ProfileTile(
              icon: Icons.shield_outlined,
              title: 'Sécurité des trajets',
              subtitle: 'Contact d\'urgence, partage de trajet, SOS',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TripSecurityScreen()),
              ),
            ),
            _ProfileTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Abonnement',
              subtitle: 'Gérer votre abonnement SunuBus',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.logout,
              title: 'Déconnexion',
              iconColor: AppColors.briqueSature,
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
