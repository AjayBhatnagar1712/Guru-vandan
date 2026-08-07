import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guruvandan_flutter/main.dart';

void main() {
  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> pumpSavedHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
      'guruvandan_flutter:language': 'english',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Enter'));
    await tester.pumpAndSettle();
  }

  testWidgets('First launch asks for language before profile',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('अपनी भाषा चुनें'), findsOneWidget);
    expect(find.text('Continue in English'), findsOneWidget);
    expect(find.text('हिंदी में आगे बढ़ें'), findsOneWidget);
    expect(find.text('Welcome to Guruvandan'), findsNothing);

    await tester.tap(find.text('Continue in English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Middle name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Today\'s Routine'), findsNothing);
  });

  test('Firebase quote records retain English and Hindi versions', () {
    final quote = WisdomQuote.fromEntry('quote-id', {
      'textEnglish': 'Meditation brings clarity.',
      'textHindi': 'ध्यान स्पष्टता लाता है।',
      'authorEnglish': 'Sadguru Maharaj',
      'authorHindi': 'सद्गुरु महाराज',
      'createdAt': 1234,
    });

    expect(quote.text, 'Meditation brings clarity.');
    expect(quote.textHindi, 'ध्यान स्पष्टता लाता है।');
    expect(quote.author, 'Sadguru Maharaj');
    expect(quote.authorHindi, 'सद्गुरु महाराज');
    expect(quote.createdAt, 1234);
  });

  testWidgets('Guruvandan home renders with first name', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
      'guruvandan_flutter:language': 'english',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Guruvandan'), findsWidgets);
    expect(find.text('Jai Guru, Ajay!'), findsOneWidget);
    expect(find.textContaining('Ajay'), findsWidgets);
    expect(find.textContaining('Bhatnagar'), findsNothing);
    expect(find.text('Today\'s Routine'), findsOneWidget);
  });

  testWidgets('Streak counts meditation days only', (tester) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final olderMeditation = now.subtract(const Duration(days: 5));
    final satsangOnly = now.subtract(const Duration(days: 4));

    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:name': 'Ajay Bhatnagar',
      'guruvandan_flutter:language': 'english',
      'guruvandan_flutter:routine': jsonEncode({
        dateKey(now): {'meditation': true},
        dateKey(yesterday): {'meditation': true},
        dateKey(olderMeditation): {'meditation': true},
        dateKey(satsangOnly): {
          'morningSatsang': true,
          'eveningSatsang': true,
        },
      }),
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    final current = tester.widget<Text>(
      find.byKey(const Key('meditation-streak-current')),
    );
    final best = tester.widget<Text>(
      find.byKey(const Key('meditation-streak-best')),
    );
    final total = tester.widget<Text>(
      find.byKey(const Key('meditation-streak-total')),
    );

    expect(current.data, '2');
    expect(best.data, '2');
    expect(total.data, '3');
    expect(find.text('Meditation streak'), findsOneWidget);
    expect(find.text('Any meditation duration counts.'), findsOneWidget);
    expect(
      find.text('Complete all three practices to grow your streak.'),
      findsNothing,
    );
  });

  testWidgets('Name onboarding saves split profile', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guruvandan_flutter:language': 'english',
    });

    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Ajay');
    await tester.enterText(find.byType(EditableText).at(1), 'Kumar');
    await tester.enterText(find.byType(EditableText).at(2), 'Bhatnagar');
    await tester.ensureVisible(find.text('Begin'));
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    expect(find.text('Jai Guru, Ajay!'), findsOneWidget);
    expect(find.textContaining('Ajay'), findsWidgets);
    expect(find.textContaining('Kumar'), findsNothing);
    expect(find.textContaining('Bhatnagar'), findsNothing);
    expect(find.text('Today\'s Routine'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsNothing);
    expect(find.text('First name'), findsNothing);
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
    expect(find.text('Om mantra'), findsOneWidget);
    expect(find.text('417Hz mantra ambience'), findsOneWidget);
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
    expect(find.text('Admin content'), findsNothing);
    expect(find.text('Open admin console'), findsNothing);
  });

  testWidgets('More tab switches app language to Hindi', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hindi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi'));
    await tester.pumpAndSettle();

    expect(find.text('भाषा'), findsOneWidget);
    expect(find.text('मॉड्यूल'), findsOneWidget);
    expect(find.text('दुकान'), findsOneWidget);
    expect(find.text('होम'), findsOneWidget);
  });

  testWidgets('Meditation start asks user to put phone on silent',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSavedHome(tester);

    await tester.tap(find.text('Dhyan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Put phone on silent'), findsOneWidget);
    expect(
      find.textContaining('Please put your phone on silent mode'),
      findsOneWidget,
    );
  });
}
