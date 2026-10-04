// test/smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autolearn/backend/api_client.dart';
import 'package:autolearn/theme/app_theme.dart';
import 'package:autolearn/utils/preference_notifier.dart';
import 'package:autolearn/widgets/economics/supply_demand_widget.dart';
import 'package:autolearn/widgets/notebook/notebook.dart';

void main() {

  group('AutoLearn Smoke Tests', () {
    test('ApiClient provides safe default baseUrl without asserting', () {
      final baseUrl = ApiClient.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, contains('/api'));
    });

    test('both themes carry notebook colours (paper vs blackboard)', () {
      final light = AppTheme.lightTheme.extension<NotebookColors>();
      final dark = AppTheme.darkTheme.extension<NotebookColors>();
      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.gridLine, isNot(dark!.gridLine));
      expect(AppTheme.lightTheme.colorScheme.surface, AppTheme.paper);
      expect(AppTheme.darkTheme.colorScheme.surface, AppTheme.board);
    });

    test('PreferenceNotifier initializes and reacts to updates', () {
      final notifier = PreferenceNotifier.instance;
      notifier.loadPreferences(
        theme: 'dark',
        fontSize: 'large',
        reduceMotion: false,
      );

      expect(notifier.themeMode, ThemeMode.dark);
      expect(notifier.fontSizeMultiplier, greaterThan(1.0));
    });

    test("equilibrium math matches the lab's linear market", () {
      final (q, p) = equilibrium(0, 0);
      expect(q, 50);
      expect(p, 60);
      // More demand: price and quantity both rise.
      final (qd, pd) = equilibrium(16, 0);
      expect(qd, greaterThan(q));
      expect(pd, greaterThan(p));
      // Less supply (drought): price rises, quantity falls.
      final (qs, ps) = equilibrium(0, -16);
      expect(qs, lessThan(q));
      expect(ps, greaterThan(p));
      expect(explainShift(0, -16), 'supply fell → price ↑, quantity ↓');
    });

    testWidgets('market lab renders, reacts to a scenario and resets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SingleChildScrollView(child: SupplyDemandInteractiveWidget())),
        ),
      );
      expect(find.text('Market equilibrium lab'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.text('60.0'), findsOneWidget); // P* at rest

      await tester.tap(find.text('Incomes rise'));
      await tester.pump();
      expect(find.text('demand rose → price ↑, quantity ↑'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset market'));
      await tester.tap(find.text('Reset market'));
      await tester.pump();
      expect(find.text('60.0'), findsOneWidget);
    });

    testWidgets('NoteText splits a paragraph from the list that follows it', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: NoteText('A simple plan:\n- Day 1: learn it\n- Day 2: recall it\n\n1. First\n2. Second')),
      ));
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('1.'), findsOneWidget);
      expect(find.textContaining('Day 1: learn it'), findsOneWidget);
      expect(find.textContaining('A simple plan: - Day'), findsNothing);
    });
  });
}
