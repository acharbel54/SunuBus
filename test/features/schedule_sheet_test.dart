import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunu_bus/features/map/widgets/stop_marker_icon.dart';
import 'package:sunu_bus/features/schedule/widgets/stop_schedule_sheet.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('tap sur un arrêt de la carte ouvre ses horaires officiels', (tester) async {
    await pumpAuthenticatedApp(tester);
    // L'onglet Carte est déjà actif par défaut (index 0).

    final stopIcon = find.byType(StopMarkerIcon).first;
    expect(stopIcon, findsOneWidget);

    // Les marqueurs de bus (animés, positions aléatoires) peuvent se
    // superposer visuellement à un arrêt dans le viewport réduit des tests :
    // on invoque directement le callback du GestureDetector du marqueur
    // plutôt qu'un tap par coordonnées, pour ne pas dépendre de cette
    // disposition changeante.
    final gestureDetector = tester.widget<GestureDetector>(
      find.ancestor(of: stopIcon, matching: find.byType(GestureDetector)),
    );
    gestureDetector.onTap!();
    await settle(tester);

    expect(find.byType(StopScheduleSheet), findsOneWidget);
    expect(find.textContaining('Prochains passages'), findsOneWidget);
  });
}
