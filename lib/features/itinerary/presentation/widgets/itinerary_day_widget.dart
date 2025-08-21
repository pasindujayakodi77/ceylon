import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:ceylon/features/itinerary/presentation/widgets/itinerary_item_widget.dart';
import 'package:flutter/material.dart';

class ItineraryDayWidget extends StatelessWidget {
  final adapter.ItineraryDay day;
  final int dayNumber;
  final VoidCallback? onAddItem;
  final VoidCallback? onEditNote;
  final Function(adapter.ItineraryItem) onItemTap;
  final Function(adapter.ItineraryItem)? onItemEdit;
  final Function(adapter.ItineraryItem)? onItemDelete;

  const ItineraryDayWidget({
    super.key,
    required this.day,
    required this.dayNumber,
    this.onAddItem,
    this.onEditNote,
    required this.onItemTap,
    this.onItemEdit,
    this.onItemDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Sort items by start time
    final sortedItems = [...day.items]
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

    return Container(
      margin: const EdgeInsets.only(bottom: CeylonTokens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(CeylonTokens.spacing16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(CeylonTokens.radiusMedium),
                topRight: Radius.circular(CeylonTokens.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                // Day number badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    dayNumber.toString(),
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: CeylonTokens.spacing12),
                // Day info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.dayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        day.formattedDate,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add item button
                if (onAddItem != null)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: onAddItem,
                    tooltip: 'Add Item',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      backgroundColor: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          // Note section
          if (day.note != null && day.note!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(CeylonTokens.spacing16),
              color: colorScheme.surface,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 20),
                  const SizedBox(width: CeylonTokens.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(day.note!, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (onEditNote != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEditNote,
                      tooltip: 'Edit Note',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          // Items list
          if (sortedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  return ItineraryItemWidget(
                    item: item,
                    onTap: () => onItemTap(item),
                    onDelete: onItemDelete != null
                        ? () => onItemDelete!(item)
                        : null,
                    onEdit: onItemEdit != null ? () => onItemEdit!(item) : null,
                    isLast: index == sortedItems.length - 1,
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 48,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: CeylonTokens.spacing8),
                    Text(
                      'No activities planned for this day',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (onAddItem != null) ...[
                      const SizedBox(height: CeylonTokens.spacing16),
                      ElevatedButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Activity'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: colorScheme.onPrimary,
                          backgroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
