import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sunu_bus/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('affiche l\'écran de connexion tant que personne n\'est connecté', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SunuBusApp()));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('affiche la carte avec la navigation à 4 onglets une fois connecté et abonné',
      (tester) async {
    await pumpAuthenticatedApp(tester);

    expect(find.text('SunuBus'), findsOneWidget);
    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Itinéraires'), findsOneWidget);
    expect(find.text('Réservations'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
