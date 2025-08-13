import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A reusable attraction detail widget
class AttractionDetailView extends StatelessWidget {
  final Attraction attraction;
  final bool showFullDetails;

  const AttractionDetailView({
    super.key,
    required this.attraction,
    this.showFullDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create Google Maps URL for directions
    final directionUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${attraction.latitude},${attraction.longitude}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image carousel or header image
        if (attraction.images.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              attraction.images.first,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and favorite button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      attraction.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FavoriteButton(attraction: attraction),
                ],
              ),

              const SizedBox(height: 8),

              // Location
              Row(
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

              // Category/tags chips
              if (attraction.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
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
                        .take(3)
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                  ],
                ),
              ],

              // Rating
              if (attraction.rating > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${attraction.rating.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Description
              if (showFullDetails) ...[
                const SizedBox(height: 16),
                Text(attraction.description, style: theme.textTheme.bodyMedium),

                // Get directions button
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text("Get Directions"),
                  onPressed: () => launchUrl(
                    directionUrl,
                    mode: LaunchMode.externalApplication,
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
