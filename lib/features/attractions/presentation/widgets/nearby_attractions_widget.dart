import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:flutter/material.dart';

class NearbyAttractionsWidget extends StatelessWidget {
  final List<Attraction> attractions;
  final Function(Attraction) onAttractionTap;

  const NearbyAttractionsWidget({
    super.key,
    required this.attractions,
    required this.onAttractionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (attractions.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Attractions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: CeylonTokens.spacing8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attractions.length,
            itemBuilder: (context, index) {
              return _buildNearbyAttractionItem(context, attractions[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyAttractionItem(
    BuildContext context,
    Attraction attraction,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onAttractionTap(attraction),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: CeylonTokens.spacing12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(CeylonTokens.radiusMedium),
                topRight: Radius.circular(CeylonTokens.radiusMedium),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: attraction.images.isNotEmpty
                    ? Image.network(
                        attraction.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.primaryContainer,
                          child: const Icon(Icons.image),
                        ),
                      )
                    : Container(
                        color: colorScheme.primaryContainer,
                        child: const Icon(Icons.image),
                      ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(attraction.category),
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attraction.category,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        attraction.rating.toString(),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
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
