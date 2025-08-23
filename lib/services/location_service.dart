import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static LocationService? _instance;
  bool _isEnabled = true;

  // Private constructor
  LocationService._();

  // Singleton pattern
  static Future<LocationService> getInstance() async {
    if (_instance == null) {
      _instance = LocationService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('location_tracking_enabled') ?? true;
  }

  Future<bool> isLocationEnabled() async {
    if (!_isEnabled) return false;
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    if (!_isEnabled) return LocationPermission.denied;
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    if (!_isEnabled) return LocationPermission.denied;
    return await Geolocator.requestPermission();
  }

  Future<Position?> getCurrentPosition() async {
    if (!_isEnabled) return null;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get position
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_tracking_enabled', enabled);
  }

  bool get isEnabled => _isEnabled;
}
