import 'package:ceylon/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// A feature card widget for the home screen
class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isPrimary ? 2 : 1,
      surfaceTintColor: isPrimary ? colorScheme.primaryContainer : null,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CeylonTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(CeylonTokens.spacing8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        ),
                  borderRadius: BorderRadius.circular(CeylonTokens.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color:
                      iconColor ??
                      (isPrimary
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: CeylonTokens.spacing12),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: CeylonTokens.spacing4),

              // Subtitle
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
