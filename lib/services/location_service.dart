import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<List<Location>> getCoordinatesFromAddress(
      String address) async {
    try {
      // The geocoding package handles permissions internally on Android
      // but may show a warning if no requestable permissions are available.
      // This is safe to ignore as geocoding doesn't require runtime location permissions,
      // only the permissions declared in AndroidManifest.xml
      return await locationFromAddress(address);
    } catch (e) {
      // Return empty list if geocoding fails
      return [];
    }
  }

  static Future<String> getAddressFromCoordinates(
      double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      // Return coordinates if reverse geocoding fails
    }
    return "$lat, $lng";
  }
}
