import 'dart:async';
import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_app_bar.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/attractions/data/attraction_repository.dart';
import 'package:ceylon/features/map/presentation/widgets/attraction_marker_card.dart';
import 'package:ceylon/features/map/presentation/widgets/map_filter_chip.dart';
import 'package:ceylon/features/map/presentation/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AttractionsMapScreenNew extends StatefulWidget {
  const AttractionsMapScreenNew({super.key});

  @override
  State<AttractionsMapScreenNew> createState() =>
      _AttractionsMapScreenNewState();
}

class _AttractionsMapScreenNewState extends State<AttractionsMapScreenNew>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AttractionRepository _attractionRepository = AttractionRepository();
  final MapController _mapController = MapController();

  List<Attraction> _attractions = [];
  List<Attraction> _filteredAttractions = [];
  String? _selectedCategory;
  Attraction? _selectedAttraction;
  bool _isLoading = true;
  Timer? _debounce;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _searchBarAnimationController;

  final _categories = [
    'All',
    'Beach',
    'Historic',
    'Mountain',
    'Park',
    'Temple',
    'Wildlife',
  ];

  // Sri Lanka centered map coordinates
  final LatLng _sriLankaCenter = const LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
    _loadAttractions();
  }

  void _initAnimationControllers() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Start animations
    _searchBarAnimationController.forward();
    _fabAnimationController.forward();
  }

  Future<void> _loadAttractions() async {
    setState(() {
      _isLoading = true;
    });

    final attractions = await _attractionRepository.getAttractions();

    setState(() {
      _attractions = attractions;
      _filteredAttractions = attractions;
      _isLoading = false;
    });
  }

  void _filterAttractions() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final category = _selectedCategory == 'All' ? null : _selectedCategory;
      final searchQuery = _searchController.text;

      final filtered = await _attractionRepository.filterAttractions(
        attractions: _attractions,
        searchQuery: searchQuery,
        category: category,
      );

      setState(() {
        _filteredAttractions = filtered;
      });
    });
  }

  void _onMarkerTap(Attraction attraction) {
    setState(() {
      _selectedAttraction = attraction;
    });

    // Center map on selected attraction
    _mapController.move(
      LatLng(attraction.latitude, attraction.longitude),
      13.0,
    );

    // Provide haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _onClearSearch() {
    _searchController.clear();
    _filterAttractions();
  }

  // Open directions in Google Maps
  Future<void> _navigateToAttraction() async {
    if (_selectedAttraction == null) return;

    final lat = _selectedAttraction!.latitude;
    final lng = _selectedAttraction!.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  void _getCurrentLocation() {
    // Placeholder for getting current location
    // This would typically use a location package
    // For now, we'll just center on Sri Lanka
    _mapController.move(_sriLankaCenter, 8.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _fabAnimationController.dispose();
    _searchBarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Animation for search bar
    final searchBarSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _searchBarAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Animation for FAB
    final fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _sriLankaCenter,
                      initialZoom: 8.0,
                      minZoom: 6.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, __) {
                        // Clear selection when tapping on the map
                        setState(() {
                          _selectedAttraction = null;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ceylon.app',
                      ),
                      MarkerClusterLayer(
                        mapController: _mapController,
                        mapCamera: _mapController.camera,
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          markers: _buildMarkers(),
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
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

            // App Bar
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CeylonAppBar(title: 'Explore Sri Lanka'),
            ),

            // Search Bar with animation
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: searchBarSlideAnimation,
                child: MapSearchBar(
                  controller: _searchController,
                  onClear: _onClearSearch,
                  onChanged: (_) => _filterAttractions(),
                  onFilterTap: () {
                    // Show filter modal
                    _showFilterModal(context);
                  },
                ),
              ),
            ),

            // Category Filter Chips
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return MapFilterChip(
                    label: category,
                    isSelected:
                        _selectedCategory == category ||
                        (_selectedCategory == null && category == 'All'),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                      _filterAttractions();
                    },
                    icon: _getCategoryIcon(category),
                  );
                },
              ),
            ),

            // Selected Attraction Card with animation
            if (_selectedAttraction != null)
              Positioned(
                bottom: CeylonTokens.spacing16,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        AttractionMarkerCard(
                          attraction: _selectedAttraction!,
                          onTap: () {
                            // Navigate to attraction details
                            Navigator.pushNamed(
                              context,
                              '/place-details',
                              arguments: _selectedAttraction,
                            );
                          },
                        ),
                        const SizedBox(height: CeylonTokens.spacing8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CeylonTokens.spacing16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _navigateToAttraction,
                                  icon: const Icon(Icons.directions),
                                  label: const Text('Get Directions'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: CeylonTokens.spacing12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Close button for card
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: CeylonTokens.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: CeylonTokens.shadowSmall,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedAttraction = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Location FAB with animation
            Positioned(
              bottom: _selectedAttraction != null
                  ? 160
                  : CeylonTokens.spacing16,
              right: CeylonTokens.spacing16,
              child: ScaleTransition(
                scale: fabScaleAnimation,
                child: FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredAttractions.map((attraction) {
      final isSelected = _selectedAttraction?.id == attraction.id;

      return Marker(
        point: LatLng(attraction.latitude, attraction.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _onMarkerTap(attraction),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(
              _getCategoryIcon(attraction.category) ?? Icons.place,
              size: isSelected ? 20 : 18,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData? _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'temple':
        return Icons.temple_buddhist;
      case 'beach':
        return Icons.beach_access;
      case 'mountain':
        return Icons.landscape;
      case 'park':
        return Icons.park;
      case 'historic':
        return Icons.history_edu;
      case 'wildlife':
        return Icons.pets;
      case 'all':
        return Icons.map;
      default:
        return Icons.place;
    }
  }

  // Filter modal
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(CeylonTokens.spacing16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(CeylonTokens.radiusLarge),
                  topRight: Radius.circular(CeylonTokens.radiusLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          CeylonTokens.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    'Filter Attractions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: CeylonTokens.spacing8),
                  Wrap(
                    spacing: CeylonTokens.spacing8,
                    runSpacing: CeylonTokens.spacing8,
                    children: _categories.map((category) {
                      final isSelected =
                          _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');
                      return MapFilterChip(
                        label: category,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            this.setState(() {
                              _selectedCategory = category == 'All'
                                  ? null
                                  : category;
                            });
                          });
                        },
                        icon: _getCategoryIcon(category),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: CeylonTokens.spacing24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterAttractions();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: CeylonTokens.spacing16,
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Unused for now, may implement custom tile update handling later
  // void _handleTileUpdates() {
  //   // Implementation for custom tile update handling
  // }
}
