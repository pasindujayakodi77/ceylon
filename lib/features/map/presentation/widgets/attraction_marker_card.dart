import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:flutter/material.dart';

class AttractionMarkerCard extends StatelessWidget {
  final Attraction attraction;
  final VoidCallback onTap;

  const AttractionMarkerCard({
    super.key,
    required this.attraction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: CeylonTokens.spacing16,
          vertical: CeylonTokens.spacing8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
          boxShadow: CeylonTokens.shadowMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(CeylonTokens.radiusMedium),
                topRight: Radius.circular(CeylonTokens.radiusMedium),
              ),
              child: attraction.images.isNotEmpty
                  ? Image.network(
                      attraction.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: colorScheme.primaryContainer,
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: colorScheme.primaryContainer,
                      child: const Center(child: Icon(Icons.image)),
                    ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    attraction.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: CeylonTokens.spacing4),
                  // Category & Rating
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(attraction.category),
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: CeylonTokens.spacing4),
                      Text(
                        attraction.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            attraction.rating.toString(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: CeylonTokens.spacing4),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: CeylonTokens.spacing4),
                      Expanded(
                        child: Text(
                          attraction.location,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
