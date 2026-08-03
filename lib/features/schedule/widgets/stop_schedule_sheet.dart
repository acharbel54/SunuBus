import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/schedule_departure.dart';
import '../../../providers/schedule_providers.dart';

void showStopScheduleSheet(BuildContext context, {required String stopName}) {
  showModalBottomSheet(
    context: context,
    // Sans cette option, une feuille modale est plafonnée à ~9/16 de la
    // hauteur d'écran : la liste d'horaires (jusqu'à 6 passages par ligne
    // desservant l'arrêt) peut alors dépasser l'espace disponible.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => StopScheduleSheet(stopName: stopName),
  );
}

/// Horaires officiels des prochains passages à un arrêt donné.
class StopScheduleSheet extends ConsumerWidget {
  final String stopName;
  const StopScheduleSheet({super.key, required this.stopName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departures = ref.watch(stopDeparturesProvider(stopName));
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: SingleChildScrollView(
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
              Row(
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(stopName, style: textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Prochains passages (horaires officiels)',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.charbonChaud.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              if (departures.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucune ligne ne dessert cet arrêt.', style: textTheme.bodyMedium),
                )
              else
                for (int i = 0; i < departures.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _DepartureTile(departure: departures[i], textTheme: textTheme),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartureTile extends StatelessWidget {
  final ScheduleDeparture departure;
  final TextTheme textTheme;
  const _DepartureTile({required this.departure, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.terracotta.withValues(alpha: 0.12),
        child: Text(
          departure.lineNumber.substring(0, 1),
          style: const TextStyle(
            color: AppColors.terracotta,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(departure.lineNumber),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (departure.isRealtime)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.podcasts, size: 14, color: AppColors.vertBaobab),
            ),
          Text(
            DateFormat.Hm('fr_FR').format(departure.scheduledTime),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
