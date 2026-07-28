import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/map/screens/home_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise les données de locale française (pour l'affichage des dates
  // dans l'écran d'abonnement, ex: "28 juillet 2026").
  await initializeDateFormatting('fr_FR', null);

  runApp(const ProviderScope(child: SunuBusApp()));
}

class SunuBusApp extends StatelessWidget {
  const SunuBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SunuBus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeMapScreen(),
    );
  }
}
