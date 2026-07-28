import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sunu_bus/main.dart';

void main() {
  testWidgets('Home map screen loads with the app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SunuBusApp()));
    await tester.pump();

    expect(find.text('SunuBus'), findsOneWidget);
  });
}
