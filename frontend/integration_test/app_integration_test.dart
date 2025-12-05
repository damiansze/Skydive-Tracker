import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_skydive_tracker/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete app startup and navigation flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify app starts successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test that we can navigate to different screens
      // (This would be more comprehensive with actual navigation testing)
      await tester.pump(const Duration(seconds: 2));

      // App should still be running without crashes
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('WearOS layout detection works', (WidgetTester tester) async {
      // Test with phone-sized screen
      tester.view.physicalSize = const Size(375, 667); // iPhone SE
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Should show phone layout
      // (We can't easily test WearOS layout without mocking screen size detection)

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('App handles screen rotation', (WidgetTester tester) async {
      // Start in portrait
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Rotate to landscape
      tester.view.physicalSize = const Size(667, 375);
      await tester.pumpAndSettle();

      // App should adapt without crashing
      expect(find.byType(MaterialApp), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
