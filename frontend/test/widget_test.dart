import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_skydive_tracker/main.dart';
import 'package:flutter_skydive_tracker/screens/home_screen_new.dart';
import 'package:flutter_skydive_tracker/services/wear_os_service.dart';

// Mock classes for testing
class MockWearOSService extends Mock implements WearOSService {}

void main() {
  group('App Widget Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('AdaptiveHomeScreen shows correct layout based on screen size', (WidgetTester tester) async {
      // Test with phone-sized screen (should show HomeScreenNew)
      tester.view.physicalSize = const Size(375, 667); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show phone layout
      expect(find.byType(HomeScreenNew), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('App uses correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('App handles missing route gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AdaptiveHomeScreen(),
            routes: {}, // No routes defined
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash and show home screen
      expect(find.byType(AdaptiveHomeScreen), findsOneWidget);
    });
  });

  group('WearOS Service Tests', () {
    late MockWearOSService mockWearOSService;

    setUp(() {
      mockWearOSService = MockWearOSService();
    });

    test('WearOSService shouldUseWatchLayout returns correct values', () {
      // Phone size should return false
      expect(WearOSService.shouldUseWatchLayout(375, 667), false);

      // WearOS size should return true
      expect(WearOSService.shouldUseWatchLayout(360, 360), true);

      // Edge cases
      expect(WearOSService.shouldUseWatchLayout(460, 460), false); // Too big
      expect(WearOSService.shouldUseWatchLayout(300, 600), false); // Too rectangular
    });

    test('WearOSService isSmallRoundScreen works correctly', () {
      // Square screen should be considered round
      expect(WearOSService.isSmallRoundScreen(360, 360), true);

      // Rectangular screen should not be round
      expect(WearOSService.isSmallRoundScreen(360, 640), false);

      // Large square screen should not be small round
      expect(WearOSService.isSmallRoundScreen(800, 800), false);
    });
  });
}
