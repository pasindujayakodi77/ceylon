import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/attractions/data/attraction_repository.dart';
import 'package:ceylon/features/attractions/presentation/widgets/nearby_attractions_widget.dart';
import 'package:ceylon/features/attractions/presentation/widgets/photo_gallery_widget.dart';
import 'package:ceylon/features/attractions/presentation/widgets/reviews_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Attraction attraction;

  const PlaceDetailsScreen({super.key, required this.attraction});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _appBarOpacity = 0;

  final AttractionRepository _attractionRepository = AttractionRepository();
  List<Attraction> _nearbyAttractions = [];
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.attraction.isFavorite;
    _setupScrollListener();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load attractions for the "Nearby Attractions" section
    final attractions = await _attractionRepository.getAttractions();

    // Create some mock reviews
    final mockReviews = [
      Review(
        userId: '1',
        userName: 'John Smith',
        userPhotoUrl:
            'https://ui-avatars.com/api/?name=John+Smith&background=random',
        rating: 4.5,
        comment:
            'Beautiful place with amazing views! Definitely worth a visit.',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        userId: '2',
        userName: 'Lisa Wong',
        userPhotoUrl:
            'https://ui-avatars.com/api/?name=Lisa+Wong&background=random',
        rating: 5.0,
        comment:
            'One of the best experiences in Sri Lanka. The staff was very friendly and helpful.',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Review(
        userId: '3',
        userName: 'David Kim',
        userPhotoUrl:
            'https://ui-avatars.com/api/?name=David+Kim&background=random',
        rating: 4.0,
        comment:
            'Great place, but a bit crowded during peak season. Try to visit early in the morning.',
        date: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    if (mounted) {
      setState(() {
        // Filter out the current attraction and limit to 5 attractions
        _nearbyAttractions = attractions
            .where((a) => a.id != widget.attraction.id)
            .take(5)
            .toList();
        _reviews = mockReviews;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final opacity = (offset / 200).clamp(0.0, 1.0);

      if (_scrollOffset != offset) {
        setState(() {
          _scrollOffset = offset;
          _appBarOpacity = opacity;
        });
      }
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // TODO: Implement favorite toggling in the repository
    // final updatedAttraction = await attractionRepository.toggleFavorite(widget.attraction);
    // if (mounted) {
    //   setState(() {
    //     _isFavorite = updatedAttraction.isFavorite;
    //   });
    // }
  }

  void _openDirections() async {
    final lat = widget.attraction.latitude;
    final lng = widget.attraction.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero image
                      widget.attraction.images.isNotEmpty
                          ? Image.network(
                              widget.attraction.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colorScheme.primaryContainer,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                            )
                          : Container(
                              color: colorScheme.primaryContainer,
                              child: const Center(
                                child: Icon(Icons.image, size: 50),
                              ),
                            ),

                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),

                      // Title and category on image
                      Positioned(
                        left: CeylonTokens.spacing16,
                        right: CeylonTokens.spacing16,
                        bottom: CeylonTokens.spacing24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.attraction.name,
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 3.0,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: CeylonTokens.spacing4),
                            Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(widget.attraction.category),
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: CeylonTokens.spacing8),
                                Text(
                                  widget.attraction.category,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(1, 1),
                                        blurRadius: 3.0,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(CeylonTokens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info row
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CeylonTokens.spacing12,
                              vertical: CeylonTokens.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                CeylonTokens.radiusSmall,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.attraction.rating.toStringAsFixed(1),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: CeylonTokens.spacing16),

                          // Location info
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.attraction.location,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: CeylonTokens.spacing24),

                      // Tags
                      if (widget.attraction.tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: CeylonTokens.spacing8),
                        Wrap(
                          spacing: CeylonTokens.spacing8,
                          runSpacing: CeylonTokens.spacing8,
                          children: widget.attraction.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: CeylonTokens.spacing12,
                                vertical: CeylonTokens.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  CeylonTokens.radiusSmall,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: CeylonTokens.spacing24),
                      ],

                      // Description
                      Text(
                        'About',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: CeylonTokens.spacing8),
                      Text(
                        widget.attraction.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: CeylonTokens.spacing24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openDirections,
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: CeylonTokens.spacing16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Add more content sections as needed
                      // Photos gallery
                      // Reviews
                      // Nearby attractions
                      // etc.
                      const SizedBox(height: CeylonTokens.spacing24),

                      // Photo gallery
                      if (widget.attraction.images.length > 1)
                        PhotoGalleryWidget(imageUrls: widget.attraction.images),

                      const SizedBox(height: CeylonTokens.spacing24),

                      // Reviews
                      if (_reviews.isNotEmpty) ReviewsWidget(reviews: _reviews),

                      const SizedBox(height: CeylonTokens.spacing24),

                      // Nearby attractions
                      if (_nearbyAttractions.isNotEmpty)
                        NearbyAttractionsWidget(
                          attractions: _nearbyAttractions,
                          onAttractionTap: (attraction) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/place-details',
                              arguments: attraction,
                            );
                          },
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Custom app bar with dynamic opacity based on scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60 + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: _appBarOpacity),
                boxShadow: _appBarOpacity > 0.1
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.1 * _appBarOpacity,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: _appBarOpacity > 0.5
                            ? colorScheme.onSurface
                            : Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Title with fade-in based on scroll
                    if (_appBarOpacity > 0.5)
                      Expanded(
                        child: Text(
                          widget.attraction.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Favorite button
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? Colors.red
                            : (_appBarOpacity > 0.5
                                  ? colorScheme.onSurface
                                  : Colors.white),
                      ),
                      onPressed: _toggleFavorite,
                    ),

                    // Share button
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: _appBarOpacity > 0.5
                            ? colorScheme.onSurface
                            : Colors.white,
                      ),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'temple':
        return Icons.temple_buddhist;
      case 'beach':
        return Icons.beach_access;
      case 'mountain':
        return Icons.landscape;
      case 'park':
        return Icons.park;
      case 'museum':
        return Icons.museum;
      case 'historic':
        return Icons.history_edu;
      case 'wildlife':
        return Icons.pets;
      case 'waterfall':
        return Icons.water;
      default:
        return Icons.place;
    }
  }
}
