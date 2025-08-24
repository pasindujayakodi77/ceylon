// FILE: lib/features/weather/presentation/widgets/weather_widget.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:intl/intl.dart';

import 'package:ceylon/features/weather/data/weather_service.dart';

/// Real weather widget (Open-Meteo + device location).
/// Drop this on Home or any screen. It finds the user's location,
/// fetches live weather, and shows a compact hourly forecast.
///
/// Usage:
///   const WeatherWidget()
/// or pass a fixed location:
///   const WeatherWidget(lat: 6.9271, lon: 79.8612, titleOverride: "Colombo")
class WeatherWidget extends StatefulWidget {
  final double? lat;
  final double? lon;
  final String? titleOverride;
  final int hours; // how many upcoming hours to show (1–24)

  const WeatherWidget({
    super.key,
    this.lat,
    this.lon,
    this.titleOverride,
    this.hours = 12,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherBundle? _data;
  String? _placeName;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    setState(() {
      if (!initial) _error = null;
    });

    try {
      double lat;
      double lon;
      if (widget.lat != null && widget.lon != null) {
        lat = widget.lat!;
        lon = widget.lon!;
      } else {
        final pos = await _resolvePosition();
        lat = pos.latitude;
        lon = pos.longitude;
      }

      // Reverse-geocode to a friendly place name (best effort)
      if (widget.titleOverride != null) {
        _placeName = widget.titleOverride!;
      } else {
        try {
          final marks = await gc.placemarkFromCoordinates(lat, lon);
          if (marks.isNotEmpty) {
            final m = marks.first;
            _placeName = [
              m.locality,
              m.administrativeArea,
              m.country,
            ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
          } else {
            _placeName = 'Your location';
          }
        } catch (_) {
          _placeName = 'Your location';
        }
      }

      final w = await WeatherService.fetch(
        lat: lat,
        lon: lon,
        hours: widget.hours.clamp(1, 24),
      );
      if (!mounted) return;
      setState(() {
        _data = w;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<Position> _resolvePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Open app settings to enable.',
      );
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Location permission denied');
      }
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  // Map Open-Meteo weather codes to built-in Material Icons for more reliable display.
  IconData _iconForCode(int code) {
    // Clear / Sunny
    if (code == 0) return Icons.wb_sunny;
    // Mainly clear / partly cloudy / overcast
    if ({1, 2, 3}.contains(code)) return Icons.wb_cloudy;
    // Fog / mist
    if ({45, 48}.contains(code)) return Icons.blur_on;
    // Drizzle
    if ({51, 53, 55, 56, 57}.contains(code)) return Icons.grain;
    // Rain
    if ({61, 63, 65, 66, 67}.contains(code)) return Icons.opacity;
    // Snow
    if ({71, 73, 75, 77}.contains(code)) return Icons.ac_unit;
    // Rain showers
    if ({80, 81, 82}.contains(code)) return Icons.grain;
    // Snow showers
    if ({85, 86}.contains(code)) return Icons.ac_unit;
    // Thunderstorm
    if ({95, 96, 99}.contains(code)) return Icons.flash_on;
    // Fallback
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    final title = _placeName ?? widget.titleOverride ?? 'Weather';

    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: _loading
          ? _buildLoading(title)
          : (_error != null
                ? _buildError(title, _error!)
                : _buildContent(title, _data!)),
    );
  }

  Widget _buildLoading(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            height: 52,
            width: 52,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Fetching live weather…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String title, String message) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.redAccent),
            title: Text(title),
            subtitle: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: () => _load(),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 6),
          if (message.contains('settings'))
            FilledButton.tonal(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text('Open app settings'),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(String title, WeatherBundle w) {
    final now = w.current;
    final small = Theme.of(context).textTheme.bodySmall;

    final iconData = _iconForCode(now.weatherCode);

    // Prefer the first hourly forecast temperature when available
    final displayTemp = w.nextHours.isNotEmpty
        ? w.nextHours.first.tempC
        : now.temperatureC;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          leading: CircleAvatar(radius: 26, child: Icon(iconData, size: 28)),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(WeatherService.describe(now.weatherCode)),
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ),

        // Big temperature + meta
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                '${displayTemp.toStringAsFixed(0)}°C',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (now.windKph != null)
                    Text(
                      'Wind: ${now.windKph!.toStringAsFixed(0)} km/h',
                      style: small,
                    ),
                  if (now.humidityPct != null)
                    Text('Humidity: ${now.humidityPct}%', style: small),
                  Text(
                    'Updated: ${DateFormat('hh:mm a').format(now.fetchedAt)}',
                    style: small,
                  ),
                ],
              ),
            ],
          ),
        ),

        // hourly chips removed per user request
      ],
    );
  }
}
