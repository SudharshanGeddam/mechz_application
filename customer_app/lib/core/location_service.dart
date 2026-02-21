import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {

    // Check if location services enabled (GPS ON)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();

     // If denied → request
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    // If permanently denied
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permission permanently denied. Please enable from settings.");
    }

    // If granted → get position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      )
    );
  }
}