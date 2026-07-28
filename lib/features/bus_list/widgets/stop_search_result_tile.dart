import 'package:flutter/material.dart';

import '../../../providers/bus_providers.dart';

/// Résultat de recherche d'arrêt : nom de l'arrêt et lignes qui le
/// desservent.
class StopSearchResultTile extends StatelessWidget {
  final StopSearchResult result;

  const StopSearchResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(result.stopName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final line in result.lines)
            Chip(
              label: Text(line.number, style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: line.color,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
