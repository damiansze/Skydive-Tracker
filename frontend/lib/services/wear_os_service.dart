import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to detect if the app is running on WearOS and get screen info
class WearOSService {
  static bool? _isWearOS;
  static bool _forceWearOS = false;

  /// Force WearOS mode (for testing only)
  static void setForceWearOS(bool enabled) {
    _forceWearOS = enabled;
  }

  /// Check if the device is a WearOS device
  static Future<bool> isWearOS() async {
    if (_forceWearOS) return true;
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
      // Fallback: assume not WearOS if platform channel fails
      _isWearOS = false;
    }
    
    return _isWearOS!;
  }

  /// Check screen size to determine if we should use WearOS layout
  /// Returns true ONLY for small, roughly square screens (actual watches)
  /// Watches: 300-454px square screens
  /// Phones: rectangular screens, usually 360-430px wide but 700-900px+ tall
  static bool shouldUseWatchLayout(double screenWidth, double screenHeight) {
    if (_forceWearOS) return true;
    
    final smallestDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    final largestDimension = screenWidth > screenHeight ? screenWidth : screenHeight;
    
    // WearOS screens are nearly SQUARE (round or square watches)
    // The aspect ratio should be close to 1.0 (typically 1.0 to 1.1)
    // Phones have aspect ratios of 1.7 to 2.2+ (tall rectangles)
    final aspectRatio = largestDimension / smallestDimension;
    
    // For WearOS: must be small AND nearly square
    // - Smallest dimension must be < 460px (watch screens are typically 360-454px)
    // - Aspect ratio must be < 1.3 (watches are square or nearly square)
    final isSmallScreen = smallestDimension < 460;
    final isNearlySquare = aspectRatio < 1.3;
    
    return isSmallScreen && isNearlySquare;
  }

  /// Check if the screen is round (common for WearOS)
  static bool isSmallRoundScreen(double screenWidth, double screenHeight) {
    if (!shouldUseWatchLayout(screenWidth, screenHeight)) return false;
    
    // Round screens typically have width ≈ height (within ~50px)
    return (screenWidth - screenHeight).abs() < 50;
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
