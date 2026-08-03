import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunu_bus/features/booking/widgets/booking_tile.dart';
import 'package:sunu_bus/features/trip_planner/widgets/itinerary_card.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'parcours complet : rechercher un itinéraire, le réserver, activer un rappel, '
    'puis annuler la réservation',
    (tester) async {
      await pumpAuthenticatedApp(tester);

      // 1. Bascule sur l'onglet "Itinéraires".
      await tester.tap(find.text('Itinéraires'));
      await settle(tester);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      // 2. Origine : "Colobane" (arrêt réel de la Ligne 4).
      await tester.tap(fields.first);
      await tester.enterText(fields.first, 'Colobane');
      await settle(tester);
      await tester.tap(find.text('Colobane').last);
      await settle(tester);

      // 3. Destination : "Guédiawaye" (terminus de la Ligne 4).
      final fieldsAfterOrigin = find.byType(TextField);
      await tester.tap(fieldsAfterOrigin.last);
      await tester.enterText(fieldsAfterOrigin.last, 'Guédiawaye');
      await settle(tester);
      await tester.tap(find.text('Guédiawaye').last);
      await settle(tester);

      // 4. Lance la recherche.
      final searchButton = find.widgetWithText(ElevatedButton, 'Rechercher');
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await settle(tester, times: 20); // laisse la latence simulée + la transition se dérouler

      // 5. Au moins un itinéraire proposé (le taxi direct est garanti).
      expect(find.byType(ItineraryCard), findsWidgets);

      // 6. Ouvre le détail du premier itinéraire.
      await tester.tap(find.byType(ItineraryCard).first);
      await settle(tester, times: 15);
      final bookButton = find.widgetWithText(ElevatedButton, 'Réserver ce trajet');
      expect(bookButton, findsOneWidget);

      // 7. Réserve le trajet.
      await tester.tap(bookButton);
      await settle(tester, times: 15);
      expect(find.text('Réservation confirmée'), findsOneWidget);

      // 8. Active le rappel avant le départ (service de notification neutralisé en test).
      final reminderSwitch = find.byType(SwitchListTile);
      expect(reminderSwitch, findsOneWidget);
      await tester.tap(reminderSwitch);
      await settle(tester);

      // 9. Va sur "Mes réservations" : le trajet réservé y apparaît, "à venir".
      await tester.tap(find.widgetWithText(ElevatedButton, 'Voir mes réservations'));
      await settle(tester, times: 15);
      expect(find.byType(BookingTile), findsOneWidget);
      // "À venir" apparaît deux fois : le titre de section et le badge de
      // statut sur la carte de réservation (même libellé, par design).
      expect(find.text('À venir'), findsNWidgets(2));
      expect(find.textContaining('Colobane'), findsWidgets);
      expect(find.textContaining('Guédiawaye'), findsWidgets);

      // 10. Annule la réservation : elle passe en "Annulé" et disparaît des "à venir".
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);
      expect(find.text('À venir'), findsNothing);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Annulé'), findsOneWidget);
    },
  );
}
