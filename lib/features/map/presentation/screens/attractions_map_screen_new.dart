import 'dart:async';
import 'package:ceylon/features/attractions/data/attractions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class AttractionsMapScreen extends StatefulWidget {
  const AttractionsMapScreen({super.key});

  @override
  State<AttractionsMapScreen> createState() => _AttractionsMapScreenState();
}

class _AttractionsMapScreenState extends State<AttractionsMapScreen> {
  final _map = MapController();
  final _repo = AttractionsRepository();

  List<AttractionPin> _pins = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load initial once the first frame has layout (bounds available)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForCurrentView());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  LatLngBounds _currentBounds() {
    final camera = _map.camera;
    return camera.visibleBounds;
  }

  void _onMapEvent(MapEvent e) {
    if (e is! MapEventMoveEnd && e is! MapEventFlingAnimationEnd) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _loadForCurrentView);
  }

  Future<void> _loadForCurrentView() async {
    final b = _currentBounds();
    setState(() => _loading = true);

    final list = await _repo.fetchInBounds(
      south: b.south,
      west: b.west,
      north: b.north,
      east: b.east,
      paddingDeg: 0.18,
    );

    if (!mounted) return;
    setState(() {
      _pins = list;
      _loading = false;
    });
  }

  List<Marker> _buildMarkers() {
    // Keep marker widgets lightweight (no network images in the pin itself)
    return _pins.map((p) {
      return Marker(
        point: LatLng(p.lat, p.lng),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _openDetails(p),
          child: _pinIcon(p),
        ),
      );
    }).toList();
  }

  Widget _pinIcon(AttractionPin p) {
    // color by category (optional)
    final cat = (p.category ?? '').toLowerCase();
    Color c = Colors.redAccent;
    if (cat.contains('beach'))
      c = Colors.blueAccent;
    else if (cat.contains('hike') || cat.contains('view'))
      c = Colors.green;
    else if (cat.contains('relig'))
      c = Colors.deepOrange;
    else if (cat.contains('wild'))
      c = Colors.brown;
    else if (cat.contains('museum') ||
        cat.contains('history') ||
        cat.contains('culture'))
      c = Colors.purple;

    return Container(
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: const Icon(Icons.place, color: Colors.white, size: 18),
    );
  }

  Future<void> _openDetails(AttractionPin p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PlaceSheet(pin: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Nearby Attractions'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _loadForCurrentView,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: const LatLng(7.8731, 80.7718), // Sri Lanka
              initialZoom: 7,
              minZoom: 5,
              maxZoom: 18,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ceylon',
              ),

              // 🔵 Cluster layer (auto groups pins at lower zooms)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: markers,
                  maxClusterRadius: 45, // cluster aggressiveness
                  disableClusteringAtZoom:
                      15, // show individual pins at high zoom
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  spiderfyCircleRadius: 40,
                  spiderfySpiralDistanceMultiplier: 2,
                  builder: (context, clusterMarkers) {
                    // The blue count bubble
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          clusterMarkers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (_loading)
            const Positioned(
              top: 8,
              right: 8,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading…'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet with image, details, and Google Maps Directions
class _PlaceSheet extends StatelessWidget {
  final AttractionPin pin;
  const _PlaceSheet({required this.pin});

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pin.lat},${pin.lng}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 46,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (pin.photo != null && pin.photo!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pin.photo!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(pin.name, style: Theme.of(context).textTheme.titleLarge),
          if ((pin.city ?? '').isNotEmpty)
            Text(pin.city!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          if ((pin.description ?? '').isNotEmpty)
            Text(pin.description!, style: const TextStyle(height: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
