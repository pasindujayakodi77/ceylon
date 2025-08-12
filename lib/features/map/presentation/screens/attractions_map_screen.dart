import 'dart:async';
import 'package:ceylon/features/attractions/data/attractions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttractionsMapScreen extends StatefulWidget {
  const AttractionsMapScreen({super.key});

  @override
  State<AttractionsMapScreen> createState() => _AttractionsMapScreenState();
}

class _AttractionsMapScreenState extends State<AttractionsMapScreen>
    with TickerProviderStateMixin {
  final _map = MapController();
  final _repo = AttractionsRepository();

  List<AttractionPin> _pins = [];
  bool _loading = true;
  Timer? _debounce;

  // Animation controllers for modern UI
  late AnimationController _fabAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _loadingRotationAnimation;

  // Search and filter state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _loadingRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loadingAnimationController);

    _fabAnimationController.forward();

    // Load initial once the first frame has layout (bounds available)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForCurrentView());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fabAnimationController.dispose();
    _loadingAnimationController.dispose();
    _searchController.dispose();
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

  List<Marker> _buildMarkersFromPins(List<AttractionPin> pins) {
    // Keep marker widgets lightweight (no network images in the pin itself)
    return pins.map((p) {
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
    // Modern color scheme by category
    final cat = (p.category ?? '').toLowerCase();
    Color primaryColor = const Color(0xFF4A90E2);
    Color accentColor = Colors.white;
    IconData iconData = Icons.place;

    if (cat.contains('beach')) {
      primaryColor = const Color(0xFF50C4ED);
      iconData = Icons.beach_access;
    } else if (cat.contains('hike') || cat.contains('view')) {
      primaryColor = const Color(0xFF7ED321);
      iconData = Icons.landscape;
    } else if (cat.contains('relig')) {
      primaryColor = const Color(0xFFD0021B);
      iconData = Icons.temple_hindu;
    } else if (cat.contains('wild')) {
      primaryColor = const Color(0xFF8B572A);
      iconData = Icons.pets;
    } else if (cat.contains('museum') ||
        cat.contains('history') ||
        cat.contains('culture')) {
      primaryColor = const Color(0xFF9013FE);
      iconData = Icons.museum;
    } else if (cat.contains('food') || cat.contains('restaurant')) {
      primaryColor = const Color(0xFFFF6B35);
      iconData = Icons.restaurant;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(iconData, color: accentColor, size: 20),
      ),
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
    // Filter pins first, then build markers from filtered pins
    final filteredPins = _searchQuery.isEmpty
        ? _pins
        : _pins
              .where(
                (pin) =>
                    pin.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (pin.description?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (pin.city?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();

    final markers = _buildMarkersFromPins(filteredPins);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600.withValues(alpha: 0.9),
                Colors.blue.shade700.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: _showSearchBar
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search attractions...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    '🌟 Discover Ceylon',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _loadForCurrentView();
                },
                icon: AnimatedBuilder(
                  animation: _loadingRotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loading
                          ? _loadingRotationAnimation.value * 6.28
                          : 0,
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                tooltip: 'Refresh attractions',
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Modern Map with enhanced styling
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

              // Enhanced Cluster layer with modern design
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: markers,
                  maxClusterRadius: 50,
                  disableClusteringAtZoom: 15,
                  size: const Size(50, 50),
                  alignment: Alignment.center,
                  spiderfyCircleRadius: 50,
                  spiderfySpiralDistanceMultiplier: 3,
                  builder: (context, clusterMarkers) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            clusterMarkers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Modern loading indicator
          if (_loading)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Discovering...',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Statistics card
          if (_pins.isNotEmpty && !_loading)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${filteredPins.length} places',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "my_location",
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
              elevation: 4,
              onPressed: () {
                HapticFeedback.lightImpact();
                // Add your location functionality here
                _map.move(const LatLng(7.8731, 80.7718), 10);
              },
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: "explore",
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 6,
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showFilterBottomSheet();
              },
              icon: const Icon(Icons.explore),
              label: const Text(
                'Explore',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filter Attractions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildFilterChip('🏖️ Beaches', 'beach'),
                  _buildFilterChip('🏔️ Mountains', 'hike'),
                  _buildFilterChip('🛕 Temples', 'relig'),
                  _buildFilterChip('🏛️ Museums', 'museum'),
                  _buildFilterChip('🐾 Wildlife', 'wild'),
                  _buildFilterChip('🍽️ Food', 'food'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _searchQuery = category;
          _searchController.text = category;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern bottom sheet with enhanced UI/UX and Google Maps integration
class _PlaceSheet extends StatefulWidget {
  final AttractionPin pin;
  const _PlaceSheet({required this.pin});

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openDirections() async {
    try {
      final lat = widget.pin.lat;
      final lng = widget.pin.lng;

      // Try Google Maps app with specific package first
      final googleMapsAppUri = Uri.parse('google.navigation:q=$lat,$lng');

      // Check if Google Maps app is available and launch it
      if (await canLaunchUrl(googleMapsAppUri)) {
        final success = await launchUrl(
          googleMapsAppUri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return;
      }

      // Fallback to Google Maps web with intent to open in app if available
      final googleMapsWebUri = Uri.parse(
        'https://maps.google.com/maps?daddr=$lat,$lng&dirflg=d',
      );

      if (await canLaunchUrl(googleMapsWebUri)) {
        final success = await launchUrl(
          googleMapsWebUri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return;
      }

      // Final fallback to Google Maps web (will open in browser)
      final fallbackUri = Uri.parse('https://maps.google.com/?q=$lat,$lng');

      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        return;
      }

      // If all attempts failed, show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps. Please check if Google Maps is installed.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening directions: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.pin.name);

    if (_isFavorite) {
      // Add to favorites
      await favRef.set({
        'name': widget.pin.name,
        'photo': widget.pin.photo ?? '',
        'desc': widget.pin.description ?? '',
        'city': widget.pin.city ?? '',
        'category': widget.pin.category ?? '',
        'lat': widget.pin.lat,
        'lng': widget.pin.lng,
        'saved_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to favorites!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } else {
      // Remove from favorites
      await favRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with modern styling
                          if (widget.pin.photo != null &&
                              widget.pin.photo!.isNotEmpty)
                            Container(
                              height: 220,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      widget.pin.photo!,
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              height: 220,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 220,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 50,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  // Gradient overlay for better text readability
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(15),
                                            ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Favorite button
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: _toggleFavorite,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isFavorite
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Title and location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.pin.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (widget.pin.city?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.pin.city!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Rating badge
                              if (widget.pin.avgRating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.pin.avgRating!.toStringAsFixed(
                                          1,
                                        ),
                                        style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          // Description
                          if (widget.pin.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 16),
                            Text(
                              'About this place',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.pin.description!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _openDirections,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: Colors.blue.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  icon: const Icon(Icons.directions, size: 20),
                                  label: const Text(
                                    'Get Directions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text(
                                    'Close',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
