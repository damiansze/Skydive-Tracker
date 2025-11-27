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
        
        return parts.isNotEmpty ? parts.join(', ') : null;
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
}
