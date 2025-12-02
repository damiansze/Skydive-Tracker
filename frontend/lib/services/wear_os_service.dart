import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to detect if the app is running on WearOS and get screen info
class WearOSService {
  static bool? _isWearOS;

  /// Check if the device is a WearOS device
  static Future<bool> isWearOS() async {
    if (_isWearOS != null) return _isWearOS!;
    
    if (!Platform.isAndroid) {
      _isWearOS = false;
      return false;
    }
    
    try {
      // Check for WearOS feature
      const platform = MethodChannel('flutter.native/helper');
      final result = await platform.invokeMethod<bool>('isWearOS');
      _isWearOS = result ?? false;
    } catch (e) {
      // Fallback: Check screen size (WearOS watches are typically < 2 inches / ~300-450px)
      // This is a heuristic and may not be 100% accurate
      _isWearOS = false;
    }
    
    return _isWearOS!;
  }

  /// Check screen size to determine if we should use WearOS layout
  /// Returns true if screen is small enough for watch UI (< 500px width/height)
  static bool shouldUseWatchLayout(double screenWidth, double screenHeight) {
    final smallestDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    return smallestDimension < 500;
  }

  /// Check if the screen is round (common for WearOS)
  static bool isSmallRoundScreen(double screenWidth, double screenHeight) {
    final smallestDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    // Most round WearOS watches have ~400-450px diameter
    return smallestDimension >= 300 && smallestDimension <= 500;
  }

  /// Get the usable radius for round screens
  static double getUsableRadius(double screenWidth, double screenHeight) {
    final diameter = screenWidth < screenHeight ? screenWidth : screenHeight;
    // Account for chin on some watches and provide padding
    return (diameter / 2) * 0.85;
  }

  /// Get safe padding for round screens (content outside circle would be cut off)
  static double getRoundScreenPadding(double screenWidth, double screenHeight) {
    final diameter = screenWidth < screenHeight ? screenWidth : screenHeight;
    // For a circle inscribed in a square, corners need extra padding
    // Padding = (diameter - diameter * sqrt(2)/2) / 2 ≈ diameter * 0.146
    return diameter * 0.12;
  }
}

/// Extension to check device type from BuildContext
extension WearOSContext on BuildContext {
  /// Check if we should use WearOS layout based on screen size
  bool get isWatchLayout {
    final size = MediaQuery.of(this).size;
    return WearOSService.shouldUseWatchLayout(size.width, size.height);
  }
  
  /// Get safe padding for round screens
  double get watchPadding {
    final size = MediaQuery.of(this).size;
    if (!isWatchLayout) return 0;
    return WearOSService.getRoundScreenPadding(size.width, size.height);
  }
}

