import 'package:flutter_test/flutter_test.dart';

import 'package:guruvandan_flutter/main.dart';

void main() {
  testWidgets('Guruvandan home renders', (WidgetTester tester) async {
    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pump();

    expect(find.text('Guruvandan'), findsWidgets);
    expect(find.text('Today\'s Routine'), findsOneWidget);
  });
}
