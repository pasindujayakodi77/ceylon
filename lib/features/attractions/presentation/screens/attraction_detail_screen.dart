import 'package:flutter/material.dart';
import 'package:ceylon/core/utils/image_url_validator.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:ceylon/features/reviews/presentation/screens/reviews_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttractionDetailScreen extends StatelessWidget {
  final Attraction attraction;

  const AttractionDetailScreen({super.key, required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          _buildSliverAppBar(context),

          // Content
          SliverToBoxAdapter(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background:
            (attraction.images.isNotEmpty &&
                isValidImageUrl(attraction.images.first))
            ? Image.network(
                attraction.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 60),
                  );
                },
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 60),
              ),
      ),
      actions: [
        FavoriteButton(attraction: attraction),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    // Create Google Maps URL for directions
    final directionUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${attraction.latitude},${attraction.longitude}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and location
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            attraction.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Location
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  attraction.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rating section
        _buildRatingSection(context),

        // Category and tags
        if (attraction.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Chip(
                  label: Text(attraction.category),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                ...attraction.tags
                    .take(5)
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontSize: 12,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
              ],
            ),
          ),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(attraction.description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),

        // Reviews preview
        _buildReviewsPreview(context),

        // Get directions button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.directions),
            label: const Text("Get Directions"),
            onPressed: () =>
                launchUrl(directionUrl, mode: LaunchMode.externalApplication),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Bottom padding for safe area
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(attraction.name)
          .snapshots(),
      builder: (context, snapshot) {
        double avgRating = attraction.rating;
        int reviewCount = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            avgRating =
                (data['avg_rating'] as num?)?.toDouble() ?? attraction.rating;
            reviewCount = (data['review_count'] as num?)?.toInt() ?? 0;
          }
        }

        return InkWell(
          onTap: () => _navigateToReviews(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                RatingBarIndicator(
                  rating: avgRating,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemSize: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _navigateToReviews(context),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('places')
                .doc(attraction.name)
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No reviews yet. Be the first to review!'),
                );
              }

              final reviews = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index].data() as Map<String, dynamic>;
                  final userName = review['name'] as String? ?? 'Anonymous';
                  final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
                  final comment = review['comment'] as String? ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemSize: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToReviews(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          attractionName: attraction.name,
          attractionPhoto: attraction.images.isNotEmpty
              ? attraction.images.first
              : null,
          attractionCategory: attraction.category,
        ),
      ),
    );
  }
}
