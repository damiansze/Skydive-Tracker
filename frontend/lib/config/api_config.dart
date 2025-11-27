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
  /// Always constructs URL dynamically based on current platform
  static String buildAssetUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // If already a full URL, extract the relative path and rebuild with current platform's baseUrl
    // This fixes the issue where iOS uploads create URLs with localhost that don't work on Android
    String actualRelativePath = relativePath;
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      // Extract the path part (everything after the domain)
      try {
        final uri = Uri.parse(relativePath);
        actualRelativePath = uri.path;
        // If path doesn't start with /api/v1/profile/picture, it might be malformed
        if (!actualRelativePath.startsWith('/api/v1/')) {
          // Try to extract just the filename and reconstruct
          final filename = uri.pathSegments.last;
          actualRelativePath = '/api/v1/profile/picture/$filename';
        }
      } catch (e) {
        // If parsing fails, try to extract path manually
        final match = RegExp(r'/(api/v1/.*)$').firstMatch(relativePath);
        if (match != null) {
          actualRelativePath = '/${match.group(1)}';
        }
      }
    }
    
    // Build full URL from current platform's baseUrl
    final baseWithoutApi = baseUrl.replaceAll('/api/v1', '');
    // Ensure relativePath starts with /
    final path = actualRelativePath.startsWith('/') ? actualRelativePath : '/$actualRelativePath';
    return '$baseWithoutApi$path';
  }
}
