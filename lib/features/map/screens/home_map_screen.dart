import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/datasources/dakar_network.dart';
import '../../../data/models/bus.dart';
import '../../../providers/bus_providers.dart';
import '../../../shared/widgets/bus_detail_sheet.dart';
import '../../bus_list/widgets/bus_list_panel.dart';
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

  void _focusOnBus(Bus bus) {
    _mapController.move(bus.position, 15);
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(busLinesProvider);
    final visibleBuses = ref.watch(filteredBusesProvider);
    final totalBusCount = ref.watch(busSimulationProvider).length;

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
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('Arrêt : ${stop.name}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                        },
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
                      width: 34,
                      height: 34,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const _LivePulseDot(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SunuBus',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$totalBusCount bus actifs en direct',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
      child: const CircleAvatar(radius: 5, backgroundColor: Colors.red),
    );
  }
}

class _SubscriptionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscriptionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.workspace_premium_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
