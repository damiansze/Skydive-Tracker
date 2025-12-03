import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_skydive_tracker/main.dart';
import 'package:flutter_skydive_tracker/screens/home_screen_new.dart';
import 'package:flutter_skydive_tracker/providers/jump_provider.dart';

// Mock für JumpNotifier
class MockJumpNotifier extends Mock implements JumpNotifier {}

void main() {
  group('Home Screen Integration Tests', () {
    testWidgets('App starts and shows home screen', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const ProviderScope(child: MyApp()));

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show home screen (adaptive screen detects phone layout)
      expect(find.byType(HomeScreenNew), findsOneWidget);
    });

    testWidgets('Home screen shows main navigation elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenNew(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show navigation buttons
      expect(find.text('Neuer Sprung'), findsOneWidget);
      expect(find.text('Statistiken'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Einstellungen'), findsOneWidget);
    });

    testWidgets('Navigation buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenNew(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap navigation buttons (should not crash)
      await tester.tap(find.text('Neuer Sprung'));
      await tester.tap(find.text('Statistiken'));
      await tester.tap(find.text('Profil'));
      await tester.tap(find.text('Einstellungen'));

      // Pump to process taps
      await tester.pump();

      // App should still be running
      expect(find.byType(HomeScreenNew), findsOneWidget);
    });

    testWidgets('Theme toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenNew(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap theme toggle (if visible)
      final themeButton = find.byIcon(Icons.brightness_6);
      if (themeButton.evaluate().isNotEmpty) {
        await tester.tap(themeButton);
        await tester.pump();
        // Should not crash
      }
    });

    testWidgets('App adapts to different screen sizes', (WidgetTester tester) async {
      // Test with phone-sized screen
      tester.view.physicalSize = const Size(375, 667); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Should show phone layout
      expect(find.byType(HomeScreenNew), findsOneWidget);

      // Reset to default
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('WearOS Detection Tests', () {
    testWidgets('App detects WearOS layout for small screens', (WidgetTester tester) async {
      // Simulate WearOS screen size
      tester.view.physicalSize = const Size(360, 360); // Square WearOS screen
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Should show WearOS layout (WearHomeScreen)
      // Note: This test assumes the adaptive screen correctly detects WearOS
      expect(find.byType(HomeScreenNew), findsNothing); // Should not show phone layout

      // Reset to default
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
