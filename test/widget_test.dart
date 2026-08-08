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

    expect(find.text('Choose the language of your journey'), findsOneWidget);
    expect(find.text('अपने साधना-पथ की भाषा चुनें'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('Welcome to Guruvandan'), findsNothing);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Middle name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Today\'s Sacred Practice'), findsNothing);
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
    expect(find.text('Today\'s Sacred Practice'), findsOneWidget);
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
    expect(find.text('Continuity of meditation'), findsOneWidget);
    expect(
      find.text(
          'Every sincere meditation, of any duration, keeps the continuity.'),
      findsOneWidget,
    );
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
    expect(find.text('Today\'s Sacred Practice'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
        const GuruvandanApp(firebaseReady: false, showOpening: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Guruvandan'), findsNothing);
    expect(find.text('First name'), findsNothing);
    expect(find.text('Today\'s Sacred Practice'), findsOneWidget);
  });

  testWidgets('Home hero morning chip opens morning satsang', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Sacred morning, evening, and aarti listening for a steadfast life of devotion.'),
      findsOneWidget,
    );
    expect(find.text('Morning Satsang'), findsOneWidget);
  });

  testWidgets('Home hero evening chip opens evening satsang', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Sacred morning, evening, and aarti listening for a steadfast life of devotion.'),
      findsOneWidget,
    );
    expect(find.text('Evening Satsang'), findsOneWidget);
  });

  testWidgets('Home hero meditation chip opens meditation', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Meditation').first);
    await tester.pumpAndSettle();

    expect(find.text('Meditation'), findsWidgets);
    expect(
      find.text(
          'Choose a duration and enter stillness. The sacred closing chant sounds only when meditation ends.'),
      findsOneWidget,
    );
    expect(find.text('Om mantra'), findsOneWidget);
    expect(find.text('417Hz sacred mantra sound'), findsOneWidget);
  });

  testWidgets('More tab shows coming soon modules', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    expect(find.text('Sacred offerings'), findsOneWidget);
    expect(find.text('Devotional Store'), findsOneWidget);
    expect(find.text('Spiritual Gatherings'), findsOneWidget);
    expect(find.text('Guru Gallery'), findsOneWidget);
    expect(find.text('Questions & Guidance'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(4));
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Admin content'), findsNothing);
    expect(find.text('Open admin console'), findsNothing);
  });

  testWidgets('More tab switches app language to Hindi', (tester) async {
    await pumpSavedHome(tester);

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hindi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi'));
    await tester.pumpAndSettle();

    expect(find.text('भाषा'), findsOneWidget);
    expect(find.text('आगामी अनुभाग'), findsOneWidget);
    expect(find.text('पूजन सामग्री'), findsOneWidget);
    expect(find.text('गृह'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
    expect(find.text('Sacred offerings'), findsNothing);
  });

  testWidgets('Bottom navigation stays aligned on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSavedHome(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Satsang'), findsOneWidget);
    final meditationLabel = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Focus'),
    );
    expect(meditationLabel, findsOneWidget);
    expect(find.text('Wisdom'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meditation start asks user to put phone on silent',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSavedHome(tester);

    await tester.tap(find.text('Meditation').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare for sacred listening'), findsOneWidget);
    expect(
      find.textContaining('Please silence your phone'),
      findsOneWidget,
    );
  });
}
