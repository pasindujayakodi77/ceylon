import 'package:ceylon/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// A weather widget for the home screen
class WeatherWidget extends StatelessWidget {
  final double temperature;
  final String condition;
  final String location;
  final IconData weatherIcon;

  const WeatherWidget({
    super.key,
    required this.temperature,
    required this.condition,
    required this.location,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(CeylonTokens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
      ),
      child: Row(
        children: [
          // Weather icon
          Container(
            padding: const EdgeInsets.all(CeylonTokens.spacing8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(weatherIcon, color: colorScheme.primary, size: 28),
          ),

          const SizedBox(width: CeylonTokens.spacing16),

          // Weather information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: CeylonTokens.spacing4),

                Row(
                  children: [
                    Text(
                      '${temperature.toStringAsFixed(0)}°C',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: CeylonTokens.spacing8),
                    Text(
                      condition,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh weather data
            },
            tooltip: 'Refresh weather data',
          ),
        ],
      ),
    );
  }

  /// Create a placeholder weather widget
  static Widget placeholder(BuildContext context) {
    return const WeatherWidget(
      temperature: 28,
      condition: 'Sunny',
      location: 'Colombo, Sri Lanka',
      weatherIcon: Icons.wb_sunny,
    );
  }
}
