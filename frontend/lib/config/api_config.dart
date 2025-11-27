import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Get the base URL for the API based on the platform
  /// 
  /// - Web: http://localhost:8000/api/v1
  /// - Android Emulator: http://10.0.2.2:8000/api/v1 (10.0.2.2 is the special IP for host machine)
  /// - iOS Simulator: http://localhost:8000/api/v1
  /// - Physical devices: Use your computer's IP address (e.g., http://192.168.1.100:8000/api/v1)
  /// 
  /// For physical devices, you can set a custom URL via environment variable or
  /// modify this method to use your computer's IP address.
  static String get baseUrl {
    // Check for custom URL from environment (useful for physical devices)
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    if (kIsWeb) {
      // Web platform
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      // For physical Android device, replace with your computer's IP address
      // Example: return 'http://192.168.1.100:8000/api/v1';
      return 'http://10.0.2.2:8000/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      // For physical iOS device, replace with your computer's IP address
      // Example: return 'http://192.168.1.100:8000/api/v1';
      return 'http://localhost:8000/api/v1';
    } else {
      // Fallback for other platforms (Linux, Windows, macOS)
      return 'http://localhost:8000/api/v1';
    }
  }

  /// Build full URL for profile picture or other assets
  /// Ensures consistent URL construction across platforms
  static String buildAssetUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // If already a full URL, return as-is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Build full URL from baseUrl
    final baseWithoutApi = baseUrl.replaceAll('/api/v1', '');
    // Ensure relativePath starts with /
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseWithoutApi$path';
  }
}
