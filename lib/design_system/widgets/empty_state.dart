// FILE: lib/design_system/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../tokens.dart';
import 'ceylon_button.dart';

/// A reusable empty state component that displays an icon, title, message,
/// and an optional action button.
///
/// Use this widget when a list, grid, or other container has no content
/// to display, either initially or after filtering.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64.0,
    this.iconColor,
    this.padding = const EdgeInsets.all(CeylonTokens.spacing32),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with subtle animation
            Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? colorScheme.primary.withOpacity(0.7),
                )
                .animate()
                .fade(duration: CeylonTokens.animationNormal)
                .slideY(
                  begin: -0.2,
                  end: 0,
                  duration: CeylonTokens.animationNormal,
                  curve: Curves.easeOutQuad,
                ),

            SizedBox(height: CeylonTokens.spacing20),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(
              duration: CeylonTokens.animationNormal,
              delay: const Duration(milliseconds: 100),
            ),

            SizedBox(height: CeylonTokens.spacing12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(
              duration: CeylonTokens.animationNormal,
              delay: const Duration(milliseconds: 200),
            ),

            // Optional action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: CeylonTokens.spacing24),
              CeylonButton.primary(
                label: actionLabel!,
                onPressed: onAction,
                leadingIcon: Icons.add_rounded,
              ).animate().fade(
                duration: CeylonTokens.animationNormal,
                delay: const Duration(milliseconds: 300),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
