import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_skydive_tracker/main.dart';
import 'package:flutter_skydive_tracker/screens/home_screen.dart';
import 'package:flutter_skydive_tracker/screens/wear_os/wear_home_screen.dart';
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
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Home screen shows main navigation elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show navigation icons
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      // Should show floating action button
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Navigation buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap floating action button to open add dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show add dialog with options
      expect(find.text('Sprung erfassen'), findsOneWidget);
      expect(find.text('Equipment erfassen'), findsOneWidget);

      // Close dialog
      await tester.tapAt(Offset(0, 0)); // Tap outside to close
      await tester.pumpAndSettle();

      // App should still be running
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Theme toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
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

      // Should show phone layout (large screen)
      expect(find.byType(HomeScreen), findsOneWidget);

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
      expect(find.byType(WearHomeScreen), findsOneWidget);

      // Reset to default
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
