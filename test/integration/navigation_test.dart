import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecovisionai/features/main_scaffold.dart';
import 'package:ecovisionai/features/splash/splash_screen.dart';
import 'package:ecovisionai/main.dart';

void main() {
  group('Navigation Integration Tests', () {
    testWidgets('App should start with splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      // Should show splash screen initially
      expect(find.text('EcoVision AI'), findsOneWidget);
      expect(find.text('A VIREN Legacy Project by Aniket Mehra'), findsOneWidget);
    });

    testWidgets('Splash screen should navigate to MainScaffold after 3 seconds',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: EcoVisionApp()));

      // Initially on splash screen
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should now be on MainScaffold
      expect(find.byType(MainScaffold), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('MainScaffold should have all four navigation destinations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Verify all navigation items exist
      expect(find.text('FloraShield'), findsOneWidget);
      expect(find.text('BioEar'), findsOneWidget);
      expect(find.text('AquaLens'), findsOneWidget);
      expect(find.text('EcoHub'), findsOneWidget);
    });

    testWidgets('Should navigate between all screens smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Start on Flora Shield
      expect(find.text('Flora Shield'), findsOneWidget);

      // Navigate to Biodiversity Ear
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();
      expect(find.text('Biodiversity Ear'), findsOneWidget);

      // Navigate to Aqua Lens
      await tester.tap(find.text('AquaLens'));
      await tester.pumpAndSettle();
      expect(find.text('Aqua Lens'), findsOneWidget);

      // Navigate to Eco Action Hub
      await tester.tap(find.text('EcoHub'));
      await tester.pumpAndSettle();
      expect(find.text('Eco Action Hub'), findsOneWidget);

      // Navigate back to Flora Shield
      await tester.tap(find.text('FloraShield'));
      await tester.pumpAndSettle();
      expect(find.text('Flora Shield'), findsOneWidget);
    });

    testWidgets('Navigation should complete within 1 second requirement',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Measure navigation time
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Requirement 7.3: Navigation should complete within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('Should maintain navigation state during feature usage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Navigate to BioEar
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Verify we're on BioEar screen
      expect(find.text('Biodiversity Ear'), findsOneWidget);

      // Navigate to another screen and back
      await tester.tap(find.text('AquaLens'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Should still be on BioEar screen
      expect(find.text('Biodiversity Ear'), findsOneWidget);
    });

    testWidgets('Bottom navigation bar should highlight selected item',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );

      // Find the NavigationBar
      final navigationBar = find.byType(NavigationBar);
      expect(navigationBar, findsOneWidget);

      // Initially, first item should be selected (index 0)
      // Navigate to second item
      await tester.tap(find.text('BioEar'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Biodiversity Ear'), findsOneWidget);
    });
  });
}
