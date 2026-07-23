import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guruvandan_flutter/main.dart';

void main() {
  testWidgets('First launch asks for full name', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Today\'s Routine'), findsNothing);
  });

  testWidgets('Guruvandan home renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Guruvandan'), findsWidgets);
    expect(find.text('Today\'s Routine'), findsOneWidget);
  });
}
