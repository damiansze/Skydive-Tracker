import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/wear_os/wear_home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/wear_os_service.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'Skydive Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const AdaptiveHomeScreen(),
      debugShowCheckedModeBanner: false,
      // Ensure keyboard doesn't block content
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Ensure text scales properly
            textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Adaptive home screen that detects screen size and shows appropriate UI
class AdaptiveHomeScreen extends StatelessWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Check if we should use WearOS layout (small round screen)
        final isWatchLayout = WearOSService.shouldUseWatchLayout(screenWidth, screenHeight);
        
        if (isWatchLayout) {
          // WearOS / Small round screen layout
          return const WearHomeScreen();
        } else {
          // Normal phone/tablet layout
          return const HomeScreen();
        }
      },
    );
  }
}
