/// Configuration class for map performance settings
class MapPerformanceConfig {
  // Maximum number of markers to show at different zoom levels
  static final Map<double, int> maxMarkersPerZoom = {
    0.0: 20, // Country level
    5.0: 50, // Region level
    8.0: 100, // City level
    10.0: 200, // District level
    12.0: 500, // Street level
    15.0: 1000, // Building level
  };

  // Clustering settings
  static const double clusteringZoomThreshold = 10.0;
  static const double clusteringDistanceKm = 5.0; // Distance in kilometers
  static const int minClusterSize = 2;

  // Performance settings
  static const int maxMarkersBeforeClustering = 50;
  static const Duration mapUpdateDebounce = Duration(milliseconds: 300);
  static const bool enableViewportFiltering = true;
  static const bool enableZoomBasedFiltering = true;

  // UI settings
  static const bool showPerformanceInfo = true;
  static const bool enableMarkerLabels = true;
  static const double minZoomForLabels = 8.0;
  static const double minZoomForDetailedMarkers = 10.0;

  /// Get maximum markers for current zoom level
  static int getMaxMarkersForZoom(double zoom) {
    for (final entry in maxMarkersPerZoom.entries.toList().reversed) {
      if (zoom >= entry.key) {
        return entry.value;
      }
    }
    return maxMarkersPerZoom.values.first;
  }

  /// Check if clustering should be enabled at current zoom level
  static bool shouldCluster(double zoom, int markerCount) {
    return zoom < clusteringZoomThreshold &&
        markerCount > maxMarkersBeforeClustering;
  }

  /// Check if marker labels should be shown
  static bool shouldShowLabels(double zoom) {
    return enableMarkerLabels && zoom >= minZoomForLabels;
  }

  /// Check if detailed markers should be shown
  static bool shouldShowDetailedMarkers(double zoom) {
    return zoom >= minZoomForDetailedMarkers;
  }
}

/// Performance optimization strategies for different scenarios
enum MapOptimizationStrategy {
  /// Show all markers (may impact performance)
  showAll,

  /// Use clustering for large datasets
  clustering,

  /// Filter by viewport only
  viewportFiltering,

  /// Combine clustering and viewport filtering (recommended)
  hybrid,

  /// Minimal markers for low-end devices
  minimal,
}

/// Map performance metrics for monitoring
class MapPerformanceMetrics {
  final int totalMarkers;
  final int visibleMarkers;
  final int clusters;
  final double currentZoom;
  final MapOptimizationStrategy strategy;
  final DateTime timestamp;

  MapPerformanceMetrics({
    required this.totalMarkers,
    required this.visibleMarkers,
    required this.clusters,
    required this.currentZoom,
    required this.strategy,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MapMetrics(total: $totalMarkers, visible: $visibleMarkers, '
        'clusters: $clusters, zoom: ${currentZoom.toStringAsFixed(1)})';
  }
}
