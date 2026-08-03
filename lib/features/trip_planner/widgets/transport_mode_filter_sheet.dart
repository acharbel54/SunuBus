import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/transport_mode.dart';
import '../../../data/models/trip_preferences.dart';
import '../../../providers/preferences_providers.dart';

Future<void> showTransportModeFilterSheet(BuildContext context, {required String phone}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => TransportModeFilterSheet(phone: phone),
  );
}

/// Filtres personnalisés de recherche d'itinéraire : modes de transport
/// autorisés, niveau de confort souhaité, temps de marche maximum.
class TransportModeFilterSheet extends ConsumerWidget {
  final String phone;
  const TransportModeFilterSheet({super.key, required this.phone});

  static const _selectableModes = [
    TransportMode.bus,
    TransportMode.tram,
    TransportMode.taxi,
    TransportMode.navette,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(tripPreferencesControllerProvider(phone));
    final controller = ref.read(tripPreferencesControllerProvider(phone).notifier);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.sableBordure,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Filtres de trajet', style: textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Modes de transport', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final mode in _selectableModes)
                  FilterChip(
                    label: Text(mode.label),
                    avatar: Icon(
                      mode.icon,
                      size: 18,
                      color: preferences.preferredModes.contains(mode) ? Colors.white : mode.color,
                    ),
                    selected: preferences.preferredModes.contains(mode),
                    onSelected: (_) => controller.toggleMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Confort', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<ComfortLevel>(
              segments: [
                for (final level in ComfortLevel.values)
                  ButtonSegment(value: level, label: Text(level.label)),
              ],
              selected: {preferences.comfortLevel},
              onSelectionChanged: (selection) => controller.setComfortLevel(selection.first),
            ),
            const SizedBox(height: 24),
            Text(
              'Marche maximum : ${preferences.maxWalkMinutes} min',
              style: textTheme.titleMedium,
            ),
            Slider(
              value: preferences.maxWalkMinutes.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              label: '${preferences.maxWalkMinutes} min',
              onChanged: (value) => controller.setMaxWalkMinutes(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}
