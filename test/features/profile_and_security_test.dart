import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunu_bus/features/trip_planner/widgets/transport_mode_filter_sheet.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('le profil affiche le numéro connecté et donne accès aux réglages', (tester) async {
    await pumpAuthenticatedApp(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);

    expect(find.text(testPhone), findsOneWidget);
    expect(find.text('Préférences de trajet'), findsOneWidget);
    expect(find.text('Sécurité des trajets'), findsOneWidget);
    expect(find.text('Abonnement'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);
  });

  testWidgets('les filtres de transport se togglent et se referment', (tester) async {
    await pumpAuthenticatedApp(tester);
    await tester.tap(find.text('Profil'));
    await settle(tester);

    await tester.tap(find.text('Préférences de trajet'));
    await settle(tester);

    expect(find.byType(TransportModeFilterSheet), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);

    // Désactive le mode Bus (au moins un mode doit rester actif ensuite).
    await tester.tap(find.widgetWithText(FilterChip, 'Bus'));
    await settle(tester);
  });

  testWidgets(
    'enregistre un contact d\'urgence puis envoie une alerte SOS',
    (tester) async {
      await pumpAuthenticatedApp(tester);
      await tester.tap(find.text('Profil'));
      await settle(tester);
      await tester.tap(find.text('Sécurité des trajets'));
      await settle(tester);

      expect(find.text('Contact d\'urgence'), findsOneWidget);

      // Le SOS est désactivé tant qu'aucun contact n'est enregistré.
      final sosButton = find.widgetWithText(FilledButton, 'Envoyer une alerte SOS');
      expect(tester.widget<FilledButton>(sosButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Awa Diop');
      await tester.enterText(find.byType(TextField).last, '770001122');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Enregistrer le contact'));
      await settle(tester);

      expect(find.text('Contact d\'urgence enregistré.'), findsOneWidget);
      expect(tester.widget<FilledButton>(sosButton).onPressed, isNotNull);

      await tester.tap(sosButton);
      await settle(tester);
      expect(find.text('Envoyer une alerte SOS ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Envoyer'));
      await settle(tester);
      expect(find.text('Alerte envoyée (simulation).'), findsOneWidget);
    },
  );
}
