import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class GeocodingService {
  /// Convert coordinates to address (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Build address string
        final parts = <String>[];
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          parts.add(placemark.street!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
          parts.add(placemark.subAdministrativeArea!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          parts.add(placemark.country!);
        }
        
        final address = parts.isNotEmpty ? parts.join(', ') : null;
        
        // Filter out Google Maps default address (1600 Amphitheatre Pkwy, Mountain View, United States)
        if (address != null) {
          final lowerAddress = address.toLowerCase();
          if (lowerAddress.contains('amphitheatre') && 
              lowerAddress.contains('mountain view')) {
            return null; // Don't return Google Maps default address
          }
        }
        
        return address;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert address to coordinates (geocoding)
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get address suggestions for autocomplete
  static Future<List<String>> getAddressSuggestions(String query) async {
    if (query.length < 3) {
      return [];
    }
    
    try {
      List<Location> locations = await locationFromAddress(query);
      List<String> suggestions = [];
      
      for (var location in locations.take(5)) {
        // Get placemark for each location to get readable address
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final parts = <String>[];
          if (placemark.street != null && placemark.street!.isNotEmpty) {
            parts.add(placemark.street!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            parts.add(placemark.locality!);
          } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
            parts.add(placemark.subAdministrativeArea!);
          }
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            parts.add(placemark.country!);
          }
          
          if (parts.isNotEmpty) {
            final address = parts.join(', ');
            // Filter out Google Maps default address
            final lowerAddress = address.toLowerCase();
            if (!(lowerAddress.contains('amphitheatre') && 
                  lowerAddress.contains('mountain view'))) {
              if (!suggestions.contains(address)) {
                suggestions.add(address);
              }
            }
          }
        }
      }
      
      return suggestions;
    } catch (e) {
      return [];
    }
  }
}
