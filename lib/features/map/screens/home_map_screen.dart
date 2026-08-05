import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/dakar_network.dart';
import '../../../data/models/bus.dart';
import '../../../providers/bus_providers.dart';
import '../../../providers/map_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../shared/widgets/bus_detail_sheet.dart';
import '../../bus_list/widgets/bus_list_panel.dart';
import '../../schedule/widgets/stop_schedule_sheet.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../widgets/bus_marker_icon.dart';
import '../widgets/stop_marker_icon.dart';

/// Écran principal : carte interactive centrée sur Dakar, affichant en
/// temps réel la position des bus simulés, les arrêts, et un panneau
/// inférieur listant les bus actifs.
class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final MapController _mapController = MapController();

  static const LatLng _dakarCenter = LatLng(14.735, -17.455);

  /// Bus déjà notifiés pour l'alerte "arrive bientôt", afin de ne pas
  /// répéter la notification à chaque tick tant que le bus reste proche.
  final Set<String> _notifiedBuses = {};

  void _focusOnBus(Bus bus) {
    _mapController.move(bus.position, 15);
  }

  void _checkApproachAlerts(List<Bus> buses) {
    final watchedLineId = ref.read(watchedLineIdProvider);
    if (watchedLineId == null) return;

    final line = DakarNetwork.lineById(watchedLineId);
    final notifications = ref.read(notificationServiceProvider);
    for (final bus in buses.where((b) => b.lineId == watchedLineId)) {
      if (bus.etaMinutes <= 3) {
        if (_notifiedBuses.add(bus.id)) {
          if (notifications.isSupported) {
            notifications.notifyBusApproaching(
              lineLabel: line.displayName,
              stopName: bus.nextStopName,
              etaMinutes: bus.etaMinutes,
            );
          } else {
            // Plateforme sans support (ex: web) : on affiche une alerte
            // visuelle à la place d'une notification système.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  '${line.displayName} arrive dans ~${bus.etaMinutes} min à ${bus.nextStopName}.',
                ),
                duration: const Duration(seconds: 4),
              ));
          }
        }
      } else if (bus.etaMinutes > 5) {
        _notifiedBuses.remove(bus.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(busLinesProvider);
    final visibleBuses = ref.watch(filteredBusesProvider);
    final totalBusCount = ref.watch(busSimulationProvider).length;
    final watchedLineId = ref.watch(watchedLineIdProvider);

    ref.listen(busSimulationProvider, (previous, next) => _checkApproachAlerts(next));

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _dakarCenter,
              initialZoom: 12.2,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dakarbus.sunu_bus',
                tileProvider: ref.watch(mapTileProviderProvider),
              ),
              // Trajets de chaque ligne, dessinés en tant que polylignes.
              PolylineLayer(
                polylines: [
                  for (final line in lines)
                    Polyline(
                      points: line.stops.map((s) => s.position).toList(),
                      color: line.color.withValues(alpha: 0.55),
                      strokeWidth: 4,
                    ),
                ],
              ),
              // Arrêts fixes du réseau.
              MarkerLayer(
                markers: [
                  for (final stop in DakarNetwork.allStops)
                    Marker(
                      point: stop.position,
                      width: 16,
                      height: 16,
                      child: GestureDetector(
                        onTap: () => showStopScheduleSheet(context, stopName: stop.name),
                        child: const StopMarkerIcon(),
                      ),
                    ),
                ],
              ),
              // Bus en mouvement (filtrés selon la ligne sélectionnée).
              MarkerLayer(
                markers: [
                  for (final bus in visibleBuses)
                    Marker(
                      point: bus.position,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => showBusDetailSheet(
                          context,
                          bus: bus,
                          line: DakarNetwork.lineById(bus.lineId),
                        ),
                        child: BusMarkerIcon(line: DakarNetwork.lineById(bus.lineId)),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Bandeau supérieur : titre, indicateur "en direct", accès abonnement.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sableCarte,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.charbonChaud.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const _LivePulseDot(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('SunuBus', style: Theme.of(context).textTheme.titleLarge),
                                Text(
                                  '$totalBusCount bus actifs en direct',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.charbonChaud.withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _HeaderIconButton(
                    icon: watchedLineId == null ? Icons.notifications_none : Icons.notifications_active,
                    onTap: () {
                      final selectedLine = ref.read(selectedLineFilterProvider);
                      if (selectedLine == null) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text('Choisissez une ligne dans la liste pour activer ses alertes.'),
                          ));
                        return;
                      }
                      ref.read(watchedLineIdProvider.notifier).state =
                          watchedLineId == selectedLine ? null : selectedLine;
                    },
                  ),
                  const SizedBox(width: 10),
                  _SubscriptionButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panneau inférieur rétractable : liste des bus, filtres, recherche.
          DraggableScrollableSheet(
            initialChildSize: 0.16,
            minChildSize: 0.12,
            maxChildSize: 0.82,
            snap: true,
            snapSizes: const [0.16, 0.5, 0.82],
            builder: (context, scrollController) {
              return BusListPanel(
                scrollController: scrollController,
                onBusTap: (bus) {
                  _focusOnBus(bus);
                  showBusDetailSheet(
                    context,
                    bus: bus,
                    line: DakarNetwork.lineById(bus.lineId),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: const CircleAvatar(radius: 5, backgroundColor: AppColors.briqueSature),
    );
  }
}

class _SubscriptionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscriptionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HeaderIconButton(icon: Icons.workspace_premium_outlined, onTap: onTap);
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
