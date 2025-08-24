// FILE: lib/features/weather/data/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal current + hourly weather model
class WeatherNow {
  final double temperatureC;
  final int weatherCode;
  final double? windKph;
  final int? humidityPct;
  final DateTime fetchedAt;

  const WeatherNow({
    required this.temperatureC,
    required this.weatherCode,
    this.windKph,
    this.humidityPct,
    required this.fetchedAt,
  });
}

class HourPoint {
  final DateTime time;
  final double tempC;
  final int code;
  final int? precipProb;
  const HourPoint({
    required this.time,
    required this.tempC,
    required this.code,
    this.precipProb,
  });
}

class WeatherBundle {
  final WeatherNow current;
  final List<HourPoint> nextHours; // usually 12–24 points
  const WeatherBundle({required this.current, required this.nextHours});
}

class WeatherService {
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch current + hourly forecast using Open-Meteo (no API key).
  static Future<WeatherBundle> fetch({
    required double lat,
    required double lon,
    int hours = 12,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'latitude': lat.toStringAsFixed(6),
        'longitude': lon.toStringAsFixed(6),
        'current':
            'temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m',
        'hourly': 'temperature_2m,weather_code,precipitation_probability',
        'timezone': 'auto',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather request failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;

    // Current
    final current = json['current'] as Map<String, dynamic>;
    final now = WeatherNow(
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      windKph: (current['wind_speed_10m'] as num?)?.toDouble(),
      humidityPct: (current['relative_humidity_2m'] as num?)?.toInt(),
      fetchedAt: DateTime.now(),
    );

    // Hourly
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final codes = (hourly['weather_code'] as List).cast<num>();
    final precs = (hourly['precipitation_probability'] as List?)?.cast<num>();

    final out = <HourPoint>[];
    final n = times.length;
    final take = hours.clamp(1, 48);
    final nowIso = DateTime.now();
    // pick the next N hours from "now"
    for (var i = 0; i < n && out.length < take; i++) {
      final t = DateTime.parse(times[i]);
      if (t.isBefore(nowIso)) continue;
      out.add(
        HourPoint(
          time: t,
          tempC: temps[i].toDouble(),
          code: codes[i].toInt(),
          precipProb: precs != null ? precs[i].toInt() : null,
        ),
      );
    }

    return WeatherBundle(current: now, nextHours: out);
  }

  /// Human text for Open-Meteo weather codes.
  static String describe(int code) {
    if (_desc.containsKey(code)) return _desc[code]!;
    // group fallback
    if ({1, 2, 3}.contains(code)) return 'Partly cloudy';
    if ({45, 48}.contains(code)) return 'Fog';
    if ({51, 53, 55, 56, 57}.contains(code)) return 'Drizzle';
    if ({61, 63, 65, 66, 67}.contains(code)) return 'Rain';
    if ({71, 73, 75, 77}.contains(code)) return 'Snow';
    if ({80, 81, 82}.contains(code)) return 'Rain showers';
    if ({85, 86}.contains(code)) return 'Snow showers';
    if ({95, 96, 99}.contains(code)) return 'Thunderstorm';
    return 'Weather';
  }

  /// A material icon suggestion for weather code.
  static int suggestedIconCodePoint(int code) {
    // Defaults
    if (code == 0) return 0xf04be; // sunny
    if ({1, 2, 3}.contains(code)) return 0xe2bd; // partly cloudy day
    if ({45, 48}.contains(code)) return 0xf0679; // mist
    if ({51, 53, 55, 56, 57}.contains(code)) return 0xf04a8; // drizzle
    if ({61, 63, 65, 66, 67}.contains(code)) return 0xe798; // rain
    if ({71, 73, 75, 77}.contains(code)) return 0xf0674; // snowy
    if ({80, 81, 82}.contains(code)) return 0xf0675; // showers
    if ({85, 86}.contains(code)) return 0xf0676; // snow showers
    if ({95, 96, 99}.contains(code)) return 0xe9bd; // thunderstorm
    return 0xe2bd; // partly cloudy fallback
  }
}

const Map<int, String> _desc = {
  0: 'Clear sky',
  1: 'Mainly clear',
  2: 'Partly cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Depositing rime fog',
  51: 'Light drizzle',
  53: 'Moderate drizzle',
  55: 'Dense drizzle',
  56: 'Light freezing drizzle',
  57: 'Dense freezing drizzle',
  61: 'Slight rain',
  63: 'Moderate rain',
  65: 'Heavy rain',
  66: 'Light freezing rain',
  67: 'Heavy freezing rain',
  71: 'Slight snow',
  73: 'Moderate snow',
  75: 'Heavy snow',
  77: 'Snow grains',
  80: 'Slight rain showers',
  81: 'Moderate rain showers',
  82: 'Violent rain showers',
  85: 'Slight snow showers',
  86: 'Heavy snow showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with slight hail',
  99: 'Thunderstorm with heavy hail',
};
