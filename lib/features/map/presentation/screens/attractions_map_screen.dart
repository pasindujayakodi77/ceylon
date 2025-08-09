import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:ceylon/features/attractions/presentation/screens/attractions_filter_screen.dart';

class AttractionsMapScreen extends StatefulWidget {
  const AttractionsMapScreen({super.key});

  @override
  State<AttractionsMapScreen> createState() => _AttractionsMapScreenState();
}

class _AttractionsMapScreenState extends State<AttractionsMapScreen> {
  final MapController _mapController = MapController();

  // Highlight state
  LatLng? _selectedLoc;
  // Removed unused _selectedPlace field
  Timer? _clearTimer;

  // Recent selections (most recent first)
  final List<Map<String, dynamic>> _recent = [];

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
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
        .collection('places')
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

              final places = snap.data!.docs.map(_normalizePlace).toList();

              // Base markers (red)
              final baseMarkers = places.map((p) {
                final point = LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                );
                return Marker(
                  point: point,
                  width: 90,
                  height: 90,
                  child: GestureDetector(
                    onTap: () => _focusAndShow(p),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 36,
                          color: Colors.red,
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            p['name'],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();

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
                  initialCenter: places.isNotEmpty
                      ? LatLng(
                          (places.first['lat'] as num).toDouble(),
                          (places.first['lng'] as num).toDouble(),
                        )
                      : const LatLng(7.8731, 80.7718),
                  initialZoom: 7.5,
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.filter_list),
        label: const Text('Find Attractions'),
        onPressed: _openFilterAndFocus,
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
