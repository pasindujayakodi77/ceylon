// FILE: lib/features/weather/data/weather_model.dart

import 'package:flutter/foundation.dart';

/// Simple model for current weather returned by Open-Meteo's
/// `current_weather` endpoint.
@immutable
class Weather {
  final double temperatureC;
  final double windSpeed;
  final int weatherCode;
  final DateTime time;

  const Weather({
    required this.temperatureC,
    required this.windSpeed,
    required this.weatherCode,
    required this.time,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Open-Meteo JSON shape: { "current_weather": { "temperature":.., "windspeed":.., "weathercode":.., "time": "..." }, ... }
    final current = json['current_weather'] as Map<String, dynamic>?;
    if (current == null) {
      throw FormatException('Missing current_weather in response');
    }

    final temp = (current['temperature'] as num?)?.toDouble();
    final wind = (current['windspeed'] as num?)?.toDouble();
    final code = (current['weathercode'] as num?)?.toInt();
    final timeStr = current['time'] as String?;

    if (temp == null || wind == null || code == null || timeStr == null) {
      throw FormatException('Invalid/missing fields in current_weather');
    }

    return Weather(
      temperatureC: temp,
      windSpeed: wind,
      weatherCode: code,
      time: DateTime.parse(timeStr).toLocal(),
    );
  }
}
