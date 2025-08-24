// FILE: lib/features/weather/presentation/weather_widget.dart

import 'package:flutter/material.dart';
import '../../weather/data/weather_service.dart';
import 'package:geolocator/geolocator.dart';

/// A small widget that shows the current temperature for the user's
/// location. It will attempt to get device location; if denied or
/// unavailable, it falls back to the provided [fallbackLatitude]
////[fallbackLongitude].
class WeatherWidget extends StatefulWidget {
  final double fallbackLatitude;
  final double fallbackLongitude;

  const WeatherWidget({
    super.key,
    this.fallbackLatitude = 6.9271, // Colombo
    this.fallbackLongitude = 79.8612,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherNow? _weather;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    double lat = widget.fallbackLatitude;
    double lon = widget.fallbackLongitude;

    WeatherNow? fetched;
    String? errorText;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lon = pos.longitude;
      } else {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.always ||
            req == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition();
          lat = pos.latitude;
          lon = pos.longitude;
        }
      }

      final bundle = await WeatherService.fetch(lat: lat, lon: lon, hours: 1);
      fetched = bundle.current;
    } catch (e) {
      errorText = e.toString();
    } finally {
      // intentionally avoid returning from finally; we'll update state below
    }

    if (!mounted) return;

    setState(() {
      _weather = fetched;
      _error = errorText;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              const Icon(Icons.error_outline, color: Colors.red)
            else if (_weather != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weather!.temperatureC.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weather!.windKph != null
                        ? 'Wind ${_weather!.windKph!.toStringAsFixed(0)} km/h'
                        : 'Wind: —',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              const Text('No data'),

            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _loadWeather,
                ),
                if (_error != null)
                  Text(
                    'Tap to retry',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
