import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/bus_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../../map/screens/home_map_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../trip_planner/screens/trip_search_screen.dart';

/// Coquille de navigation principale, affichée une fois l'utilisateur
/// authentifié et abonné : 4 onglets façon Weego (Carte, Itinéraires,
/// Réservations, Profil).
///
/// Utilise un [IndexedStack] plutôt qu'un `Navigator` par onglet afin de
/// préserver l'état de la simulation temps réel des bus (carte, timers)
/// quand l'utilisateur navigue entre les onglets.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Observe le cycle de vie de l'app pour mettre la simulation en pause en
    // arrière-plan (batterie) et la relancer au retour au premier plan.
    WidgetsBinding.instance.addObserver(this);
    // Demande la permission de notifications dès l'entrée dans l'app
    // authentifiée, pour que les alertes "bus proche" et rappels de trajet
    // fonctionnent sans friction supplémentaire plus tard.
    Future.microtask(() => ref.read(notificationServiceProvider).init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final simulation = ref.read(busSimulationProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        simulation.resume();
      case AppLifecycleState.inactive:
        // Interruption brève (panneau de notifications, boîte de dialogue
        // système, appel entrant) : l'app reste visible, on ne coupe pas la
        // simulation pour éviter un gel visible de la carte "en direct".
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        simulation.pause();
    }
  }

  static const _screens = [
    HomeMapScreen(),
    TripSearchScreen(),
    MyBookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Carte'),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Itinéraires',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_seat_outlined),
            selectedIcon: Icon(Icons.event_seat),
            label: 'Réservations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
