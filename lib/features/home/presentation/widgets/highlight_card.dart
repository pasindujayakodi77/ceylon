import 'package:ceylon/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// A highlight card for featured attractions or content
class HighlightCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Color backgroundColor;
  final IconData? icon;
  final VoidCallback onTap;
  final bool hasBadge;
  final String? badgeText;

  const HighlightCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.backgroundColor,
    this.icon,
    required this.onTap,
    this.hasBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(right: CeylonTokens.spacing12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
          boxShadow: CeylonTokens.shadowSmall,
        ),
        child: Stack(
          children: [
            // Image or color background
            if (imageUrl != null)
              Positioned.fill(
                child: Image.network(imageUrl!, fit: BoxFit.cover),
              ),

            // Gradient overlay for text visibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon if provided
                  if (icon != null) ...[
                    Icon(icon, size: 32, color: Colors.white),
                    const SizedBox(height: CeylonTokens.spacing12),
                  ],

                  const Spacer(),

                  // Badge if enabled
                  if (hasBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing8,
                        vertical: CeylonTokens.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          CeylonTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        badgeText ?? 'Featured',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: CeylonTokens.spacing8),
                  ],

                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Subtitle if provided
                  if (subtitle != null) ...[
                    const SizedBox(height: CeylonTokens.spacing4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
