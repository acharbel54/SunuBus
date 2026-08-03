import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/itinerary.dart';
import '../../../data/models/itinerary_leg.dart';
import '../../../data/models/transport_mode.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/booking_providers.dart';
import '../../../providers/map_providers.dart';
import '../../booking/screens/booking_confirmation_screen.dart';

class ItineraryDetailScreen extends ConsumerWidget {
  final Itinerary itinerary;
  const ItineraryDetailScreen({super.key, required this.itinerary});

  Future<void> _book(BuildContext context, WidgetRef ref) async {
    final phone = ref.read(authControllerProvider).phone!;
    final booking = await ref.read(bookingControllerProvider(phone).notifier).create(
          originLabel: itinerary.legs.first.fromLabel,
          destinationLabel: itinerary.legs.last.toLabel,
          primaryMode: itinerary.primaryModes.isNotEmpty
              ? itinerary.primaryModes.first
              : itinerary.legs.first.mode,
          scheduledAt: itinerary.departureTime,
          priceFcfa: itinerary.totalPriceFcfa,
          durationMinutes: itinerary.totalDurationMinutes,
        );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingConfirmationScreen(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final allPoints = itinerary.legs.expand((l) => l.points).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'itinéraire')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(allPoints),
                      padding: const EdgeInsets.all(32),
                    ),
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dakarbus.sunu_bus',
                      tileProvider: ref.watch(mapTileProviderProvider),
                    ),
                    PolylineLayer(
                      polylines: [
                        for (final leg in itinerary.legs)
                          Polyline(
                            points: leg.points,
                            color: leg.mode.color,
                            strokeWidth: 4,
                            pattern: leg.mode.baseFareFcfa == 0
                                ? const StrokePattern.dotted()
                                : const StrokePattern.solid(),
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (final point in [allPoints.first, allPoints.last])
                          Marker(
                            point: point,
                            width: 14,
                            height: 14,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final leg in itinerary.legs) _LegTile(leg: leg),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Départ ${DateFormat.Hm('fr_FR').format(itinerary.departureTime)}',
                                style: textTheme.bodyMedium),
                            Text('Arrivée ${DateFormat.Hm('fr_FR').format(itinerary.arrivalTime)}',
                                style: textTheme.bodyMedium),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${itinerary.totalPriceFcfa.round()} FCFA',
                          style: textTheme.headlineSmall?.copyWith(color: AppColors.terracotta),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () => _book(context, ref),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Réserver ce trajet'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegTile extends StatelessWidget {
  final ItineraryLeg leg;
  const _LegTile({required this.leg});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: leg.mode.color.withValues(alpha: 0.15),
            child: Icon(leg.mode.icon, size: 16, color: leg.mode.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${leg.fromLabel} → ${leg.toLabel}', style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${leg.mode.label} · ${leg.durationMinutes} min'
                  '${leg.priceFcfa > 0 ? ' · ${leg.priceFcfa.round()} FCFA' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.charbonChaud.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
