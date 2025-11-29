import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecovisionai/main.dart';
import 'package:ecovisionai/features/main_scaffold.dart';
import 'package:ecovisionai/features/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('App Initialization Tests', () {
    testWidgets('App should initialize with splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      // Requirement 6.1: Display splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('EcoVision AI'), findsOneWidget);
    });

    testWidgets('Splash screen should show proper attribution', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      // Requirement 6.2, 6.3: Display attribution
      expect(find.text('EcoVision AI'), findsOneWidget);
      expect(find.text('A VIREN Legacy Project by Aniket Mehra'), findsOneWidget);
    });

    testWidgets('Should navigate to main app after 3 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      // Initially on splash
      expect(find.byType(SplashScreen), findsOneWidget);

      // Requirement 6.4: Navigate after 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should be on main scaffold
      expect(find.byType(MainScaffold), findsOneWidget);
    });
  });

  group('MainScaffold Navigation Tests', () {
    testWidgets('MainScaffold should have four navigation destinations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Requirement 7.1: Bottom navigation bar with four destinations
      expect(find.byType(NavigationBar), findsOneWidget);

      // Requirement 7.2: All four destinations present
      expect(find.text('FloraShield'), findsOneWidget);
      expect(find.text('BioEar'), findsOneWidget);
      expect(find.text('AquaLens'), findsOneWidget);
      expect(find.text('EcoHub'), findsOneWidget);
    });

    testWidgets('Navigation should switch between screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Initially should show Flora Shield screen
      expect(find.text('Flora Shield'), findsOneWidget);

      // Tap on BioEar navigation item
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Should now show Biodiversity Ear screen
      expect(find.text('Biodiversity Ear'), findsOneWidget);

      // Tap on AquaLens navigation item
      await tester.tap(find.text('AquaLens'));
      await tester.pumpAndSettle();

      // Should now show Aqua Lens screen
      expect(find.text('Aqua Lens'), findsOneWidget);

      // Tap on EcoHub navigation item
      await tester.tap(find.text('EcoHub'));
      await tester.pumpAndSettle();

      // Should now show Eco Action Hub screen
      expect(find.text('Eco Action Hub'), findsOneWidget);
    });

    testWidgets('Navigation transitions should complete within 1 second', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Requirement 7.3: Navigation within 1 second
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.text('Biodiversity Ear'), findsOneWidget);
    });

    testWidgets('Should maintain navigation state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Requirement 7.4: Maintain navigation state
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.text('AquaLens'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Should still be on correct screen
      expect(find.text('Biodiversity Ear'), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    testWidgets('App should use Material 3 dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Requirement 7.5: Material 3 dark theme
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme!.brightness, Brightness.dark);
    });
  });

  group('Feature Screen Tests', () {
    testWidgets('Flora Shield screen should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Should start on Flora Shield
      expect(find.text('Flora Shield'), findsOneWidget);
    });

    testWidgets('Biodiversity Ear screen should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      expect(find.text('Biodiversity Ear'), findsOneWidget);
    });

    testWidgets('Aqua Lens screen should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      await tester.tap(find.text('AquaLens'));
      await tester.pumpAndSettle();

      expect(find.text('Aqua Lens'), findsOneWidget);
    });

    testWidgets('Eco Action Hub screen should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      await tester.tap(find.text('EcoHub'));
      await tester.pumpAndSettle();

      expect(find.text('Eco Action Hub'), findsOneWidget);
    });
  });
}
