import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guruvandan_flutter/main.dart';

void main() {
  Future<void> pumpSavedHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Enter'));
    await tester.pumpAndSettle();
  }

  testWidgets('First launch asks for split name', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Middle name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Today\'s Routine'), findsNothing);
  });

  testWidgets('Guruvandan home renders with first name', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Guruvandan'), findsWidgets);
    expect(find.text('जय गुरु, Ajay!'), findsOneWidget);
    expect(find.textContaining('Ajay'), findsWidgets);
    expect(find.textContaining('Bhatnagar'), findsNothing);
    expect(find.text('Today\'s Routine'), findsOneWidget);
  });

  testWidgets('Name onboarding saves split profile', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Ajay');
    await tester.enterText(find.byType(EditableText).at(1), 'Kumar');
    await tester.enterText(find.byType(EditableText).at(2), 'Bhatnagar');
    await tester.ensureVisible(find.text('Begin'));
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    expect(find.text('जय गुरु, Ajay!'), findsOneWidget);
    expect(find.textContaining('Ajay'), findsWidgets);
    expect(find.textContaining('Kumar'), findsNothing);
    expect(find.textContaining('Bhatnagar'), findsNothing);
    expect(find.text('Today\'s Routine'), findsOneWidget);
  });

  testWidgets('Home hero morning chip opens morning satsang', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Morning satsang').first);
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Morning, evening, and aarti audio for steady daily devotion.'),
        findsOneWidget);
    expect(find.text('Morning Satsang'), findsOneWidget);
  });

  testWidgets('Home hero evening chip opens evening satsang', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Evening satsang').first);
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Morning, evening, and aarti audio for steady daily devotion.'),
        findsOneWidget);
    expect(find.text('Shaam Satsang'), findsOneWidget);
  });

  testWidgets('Home hero dhyan chip opens meditation', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Dhyan'));
    await tester.pumpAndSettle();

    expect(find.text('Meditation'), findsOneWidget);
    expect(
        find.text(
            'Set your duration. The chime plays only when the timer ends.'),
        findsOneWidget);
  });

  testWidgets('More tab shows coming soon modules', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Modules'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Guru Gallery'), findsOneWidget);
    expect(find.text('Jigyasa'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(4));
  });
}
