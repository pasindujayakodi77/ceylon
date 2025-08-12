import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:ceylon/features/attractions/presentation/screens/attractions_filter_screen.dart';

// Marker cluster class for grouping nearby markers
class MarkerCluster {
  final LatLng center;
  final List<Map<String, dynamic>> places;
  final int count;

  MarkerCluster({
    required this.center,
    required this.places,
    required this.count,
  });
}

class AttractionsMapScreen extends StatefulWidget {
  const AttractionsMapScreen({super.key});

  @override
  State<AttractionsMapScreen> createState() => _AttractionsMapScreenState();
}

class _AttractionsMapScreenState extends State<AttractionsMapScreen> {
  final MapController _mapController = MapController();

  // Highlight state
  LatLng? _selectedLoc;
  Timer? _clearTimer;

  // Recent selections (most recent first)
  final List<Map<String, dynamic>> _recent = [];

  // Performance optimization variables
  double _currentZoom = 7.5;
  LatLngBounds? _currentBounds;
  List<Map<String, dynamic>> _allPlaces = [];
  List<Map<String, dynamic>> _visiblePlaces = [];

  // Clustering
  List<MarkerCluster> _clusters = [];

  @override
  void initState() {
    super.initState();
    _mapController.mapEventStream.listen(_onMapEvent);
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  // Handle map events for performance optimization
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      setState(() {
        _currentZoom = _mapController.camera.zoom;
        _currentBounds = _mapController.camera.visibleBounds;
      });
      _updateVisiblePlaces();
    }
  }

  // Update visible places based on current viewport and zoom
  void _updateVisiblePlaces() {
    if (_currentBounds == null) return;

    final visiblePlaces = _allPlaces.where((place) {
      final lat = (place['lat'] as num).toDouble();
      final lng = (place['lng'] as num).toDouble();
      final point = LatLng(lat, lng);

      return _currentBounds!.contains(point);
    }).toList();

    // Limit markers based on zoom level for performance
    final maxMarkers = _getMaxMarkersForZoom(_currentZoom);

    if (visiblePlaces.length > maxMarkers) {
      // Sort by rating and take the best ones
      visiblePlaces.sort((a, b) {
        final ratingA = (a['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['avg_rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
      _visiblePlaces = visiblePlaces.take(maxMarkers).toList();
    } else {
      _visiblePlaces = visiblePlaces;
    }

    // Create clusters if zoom level is low and many markers
    if (_currentZoom < 10 && _visiblePlaces.length > 20) {
      _clusters = _createClusters(_visiblePlaces);
    } else {
      _clusters = [];
    }
  }

  int _getMaxMarkersForZoom(double zoom) {
    if (zoom < 8) return 50;
    if (zoom < 10) return 100;
    if (zoom < 12) return 200;
    return 500; // Show all at high zoom
  }

  // Simple clustering algorithm
  List<MarkerCluster> _createClusters(List<Map<String, dynamic>> places) {
    final clusters = <MarkerCluster>[];
    final processed = <bool>[...List.filled(places.length, false)];

    for (int i = 0; i < places.length; i++) {
      if (processed[i]) continue;

      final clusterPlaces = <Map<String, dynamic>>[places[i]];
      processed[i] = true;

      final centerLat = (places[i]['lat'] as num).toDouble();
      final centerLng = (places[i]['lng'] as num).toDouble();

      // Find nearby places to cluster
      for (int j = i + 1; j < places.length; j++) {
        if (processed[j]) continue;

        final lat = (places[j]['lat'] as num).toDouble();
        final lng = (places[j]['lng'] as num).toDouble();

        // Simple distance check (in degrees, rough approximation)
        final distance = math.sqrt(
          math.pow(centerLat - lat, 2) + math.pow(centerLng - lng, 2),
        );

        if (distance < 0.05) {
          // ~5km clustering radius
          clusterPlaces.add(places[j]);
          processed[j] = true;
        }
      }

      if (clusterPlaces.length > 1) {
        // Calculate cluster center
        double avgLat = 0;
        double avgLng = 0;
        for (final place in clusterPlaces) {
          avgLat += (place['lat'] as num).toDouble();
          avgLng += (place['lng'] as num).toDouble();
        }
        avgLat /= clusterPlaces.length;
        avgLng /= clusterPlaces.length;

        clusters.add(
          MarkerCluster(
            center: LatLng(avgLat, avgLng),
            places: clusterPlaces,
            count: clusterPlaces.length,
          ),
        );
      }
    }

    return clusters;
  }

  // Create a marker for a single place
  Marker _createPlaceMarker(Map<String, dynamic> place) {
    final point = LatLng(
      (place['lat'] as num).toDouble(),
      (place['lng'] as num).toDouble(),
    );

    return Marker(
      point: point,
      width: 90,
      height: 90,
      child: GestureDetector(
        onTap: () => _focusAndShow(place),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: _currentZoom > 10 ? 36 : 28,
              color: Colors.red,
            ),
            if (_currentZoom > 8)
              SizedBox(
                width: 80,
                child: Text(
                  place['name'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _currentZoom > 10 ? 11 : 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Show cluster dialog with list of places
  void _showClusterDialog(MarkerCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cluster.count} Attractions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: cluster.places.length,
            itemBuilder: (context, index) {
              final place = cluster.places[index];
              return ListTile(
                leading: const Icon(Icons.place, color: Colors.red),
                title: Text(place['name']),
                subtitle: Text(place['desc']),
                onTap: () {
                  Navigator.of(context).pop();
                  _focusAndShow(place);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Normalize Firestore place doc to a simple map with lat/lng doubles
  Map<String, dynamic> _normalizePlace(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    double? lat;
    double? lng;

    final loc = d['location'];
    if (loc is GeoPoint) {
      lat = loc.latitude;
      lng = loc.longitude;
    } else if (loc is Map<String, dynamic>) {
      lat = (loc['latitude'] as num?)?.toDouble();
      lng = (loc['longitude'] as num?)?.toDouble();
    } else {
      lat = (d['lat'] as num?)?.toDouble();
      lng = (d['lng'] as num?)?.toDouble();
    }

    return {
      'id': doc.id,
      'name': d['name'] ?? doc.id,
      'desc': d['desc'] ?? '',
      'photo': d['photo'] ?? '',
      'lat': lat ?? 0.0,
      'lng': lng ?? 0.0,
      'avg_rating': (d['avg_rating'] is num)
          ? (d['avg_rating'] as num).toDouble()
          : null,
      'review_count': d['review_count'] ?? 0,
      'category': d['category'] ?? 'other',
    };
  }

  void _addToRecent(Map<String, dynamic> place) {
    _recent.removeWhere((e) => e['id'] == place['id']);
    _recent.insert(0, place);
    if (_recent.length > 5) _recent.removeLast();
    setState(() {});
  }

  void _focusAndShow(Map<String, dynamic> place) {
    final lat = (place['lat'] as num).toDouble();
    final lng = (place['lng'] as num).toDouble();
    final target = LatLng(lat, lng);

    _mapController.move(target, 14.0);

    setState(() {
      _selectedLoc = target;
    });

    _addToRecent(place);

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _selectedLoc = null);
    });

    _openDetailsSheet(place);
  }

  void _openDetailsSheet(Map<String, dynamic> place) {
    final loc = LatLng(
      (place['lat'] as num).toDouble(),
      (place['lng'] as num).toDouble(),
    );
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _AttractionDetails(
        attraction: {
          'name': place['name'],
          'desc': place['desc'],
          'photo': place['photo'],
          'location': loc,
          'avg_rating': place['avg_rating'],
          'review_count': place['review_count'],
          'category': place['category'],
        },
      ),
    );
  }

  Future<void> _openFilterAndFocus() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttractionsFilterScreen()),
    );
    if (selected != null && mounted) {
      final m = Map<String, dynamic>.from(selected);
      final lat = (m['lat'] ?? m['location']?['latitude']) as num? ?? 0.0;
      final lng = (m['lng'] ?? m['location']?['longitude']) as num? ?? 0.0;
      m['lat'] = lat.toDouble();
      m['lng'] = lng.toDouble();
      m['id'] ??= m['name'];
      _focusAndShow(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placesStream = FirebaseFirestore.instance
        .collection('attractions')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('📍 Attractions Map')),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: placesStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData) {
                return const Center(child: Text('No places found'));
              }

              // Update all places and trigger optimization
              _allPlaces = snap.data!.docs.map(_normalizePlace).toList();

              // Initialize bounds if not set
              if (_currentBounds == null && _allPlaces.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _currentBounds = _mapController.camera.visibleBounds;
                  _updateVisiblePlaces();
                });
              }

              // Use visible places for rendering or all if not filtered yet
              final placesToShow = _visiblePlaces.isNotEmpty
                  ? _visiblePlaces
                  : (_allPlaces.length > 100
                        ? _allPlaces.take(100).toList()
                        : _allPlaces);

              // Create markers for individual places
              final baseMarkers = <Marker>[];

              // Show clusters if available
              if (_clusters.isNotEmpty) {
                // Add cluster markers
                for (final cluster in _clusters) {
                  baseMarkers.add(
                    Marker(
                      point: cluster.center,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showClusterDialog(cluster),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${cluster.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Add unclustered places
                final clusteredPlaceIds = _clusters
                    .expand((c) => c.places)
                    .map((p) => p['id'])
                    .toSet();

                final unclusteredPlaces = placesToShow
                    .where((p) => !clusteredPlaceIds.contains(p['id']))
                    .toList();

                for (final place in unclusteredPlaces) {
                  baseMarkers.add(_createPlaceMarker(place));
                }
              } else {
                // No clustering, show all visible places
                for (final place in placesToShow) {
                  baseMarkers.add(_createPlaceMarker(place));
                }
              }

              // Selected highlight markers (pulse ring + blue pin)
              final highlightMarkers = <Marker>[];
              if (_selectedLoc != null) {
                highlightMarkers.add(
                  Marker(
                    point: _selectedLoc!,
                    width: 140,
                    height: 140,
                    child: const _PulseMarker(),
                    alignment: Alignment.center,
                  ),
                );
                highlightMarkers.add(
                  Marker(
                    point: _selectedLoc!,
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      size: 44,
                      color: Colors.blue,
                    ),
                  ),
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _allPlaces.isNotEmpty
                      ? LatLng(
                          (_allPlaces.first['lat'] as num).toDouble(),
                          (_allPlaces.first['lng'] as num).toDouble(),
                        )
                      : const LatLng(7.8731, 80.7718),
                  initialZoom: 7.5,
                  onMapEvent: _onMapEvent,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ceylon',
                  ),
                  MarkerLayer(markers: baseMarkers),
                  if (highlightMarkers.isNotEmpty)
                    MarkerLayer(markers: highlightMarkers),
                ],
              );
            },
          ),

          // Performance info
          Positioned(
            top: 60,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Showing ${_visiblePlaces.isNotEmpty ? _visiblePlaces.length : _allPlaces.length} of ${_allPlaces.length} places\n'
                'Zoom: ${_currentZoom.toStringAsFixed(1)}'
                '${_clusters.isNotEmpty ? '\nClusters: ${_clusters.length}' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

          // Recent selections chips
          if (_recent.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final r = _recent[i];
                    return ActionChip(
                      avatar: const Icon(Icons.place, size: 18),
                      label: Text(r['name'], overflow: TextOverflow.ellipsis),
                      onPressed: () => _focusAndShow(r),
                      backgroundColor: Colors.white,
                      elevation: 2,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "settings",
            mini: true,
            onPressed: _showPerformanceSettings,
            child: const Icon(Icons.settings),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "filter",
            icon: const Icon(Icons.filter_list),
            label: const Text('Find Attractions'),
            onPressed: _openFilterAndFocus,
          ),
        ],
      ),
    );
  }

  // Show performance settings dialog
  void _showPerformanceSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Performance Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('• Total Places: ${_allPlaces.length}'),
            Text('• Visible Places: ${_visiblePlaces.length}'),
            Text('• Clusters: ${_clusters.length}'),
            Text('• Current Zoom: ${_currentZoom.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text('Tips for better performance:'),
            const SizedBox(height: 8),
            const Text('• Zoom in to see more detailed markers'),
            const Text('• Clusters appear at zoom levels < 10'),
            const Text('• Marker count is limited based on zoom'),
            const Text('• Move the map to load different areas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Pulsing ring to draw attention to the focused marker.
class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scale = Tween<double>(
      begin: 0.4,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.scale(
              scale: 0.8 + (_scale.value - 0.4) * 0.6,
              child: Opacity(
                opacity: (_opacity.value * 0.8).clamp(0.0, 1.0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

/// TEMP stub of your details sheet.
/// Replace with your real bottom sheet (the one that already has Directions, Favorites, Reviews, etc.).
class _AttractionDetails extends StatelessWidget {
  final Map<String, dynamic> attraction;
  const _AttractionDetails({required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        children: [
          Text(
            attraction['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if ((attraction['photo'] ?? '').toString().isNotEmpty)
            Image.network(attraction['photo'], height: 160, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(attraction['desc'] ?? ''),
          const SizedBox(height: 16),
          // keep your existing buttons/widgets here
        ],
      ),
    );
  }
}
