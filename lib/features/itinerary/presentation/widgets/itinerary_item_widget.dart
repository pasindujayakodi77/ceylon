import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:flutter/material.dart';

class ItineraryItemWidget extends StatelessWidget {
  final adapter.ItineraryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isLast;

  const ItineraryItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CeylonTokens.spacing8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            SizedBox(
              width: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Time dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.type.color.withOpacity(0.2),
                      border: Border.all(color: item.type.color, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Timeline line
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 2,
                        height: 60,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: CeylonTokens.spacing8),
            // Time
            SizedBox(
              width: 50,
              child: Text(
                item.formattedStartTime,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: CeylonTokens.spacing8),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(CeylonTokens.spacing12),
                decoration: BoxDecoration(
                  color: item.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    CeylonTokens.radiusMedium,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.type.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              CeylonTokens.radiusSmall,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.typeIcon,
                                size: 12,
                                color: item.type.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.type.displayName,
                                style: textTheme.bodySmall?.copyWith(
                                  color: item.type.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (item.endTime != null)
                          Text(
                            'Until ${item.formattedEndTime}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: CeylonTokens.spacing8),
                    // Title
                    Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.locationName != null &&
                        item.locationName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.locationName!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.cost != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$${item.cost!.toStringAsFixed(2)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Action buttons
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(height: CeylonTokens.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: onEdit,
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                              ),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: onDelete,
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
