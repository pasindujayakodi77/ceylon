import 'package:ceylon/design_system/tokens.dart';
import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      margin: const EdgeInsets.all(CeylonTokens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        boxShadow: CeylonTokens.shadowMedium,
      ),
      child: Row(
        children: [
          const SizedBox(width: CeylonTokens.spacing12),
          Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: CeylonTokens.spacing8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search attractions',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
              color: colorScheme.onSurfaceVariant,
            ),
          if (onFilterTap != null) ...[
            Container(
              height: 24,
              width: 1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(
                horizontal: CeylonTokens.spacing8,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: onFilterTap,
              color: colorScheme.primary,
            ),
          ],
          const SizedBox(width: CeylonTokens.spacing8),
        ],
      ),
    );
  }
}
