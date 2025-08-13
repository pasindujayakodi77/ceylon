// FILE: lib/features/calendar/presentation/widgets/event_list_tile.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/calendar_event.dart';

class EventListTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onBookWhatsApp;
  final VoidCallback? onOpenForm;
  final VoidCallback? onAddToItinerary;
  final VoidCallback? onToggleSave;
  final bool isSaved;

  const EventListTile({
    super.key,
    required this.event,
    this.onBookWhatsApp,
    this.onOpenForm,
    this.onAddToItinerary,
    this.onToggleSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading banner thumbnail
                if (event.banner != null) ...[
                  _buildBannerThumbnail(),
                  const SizedBox(width: 12.0),
                ],

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),

                      // Business name and city
                      Text(
                        _buildLocationText(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4.0),

                      // Time range
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16.0,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            event.formattedTimeRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Promo chip if present
                      if (_hasPromo) ...[
                        const SizedBox(height: 8.0),
                        _buildPromoChip(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12.0),

            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Book via WhatsApp
                if (onBookWhatsApp != null)
                  _ActionButton(
                    icon: Icons.phone,
                    label: 'WhatsApp',
                    onTap: onBookWhatsApp!,
                    color: Colors.green,
                  ),

                // Open booking form
                if (onOpenForm != null) ...[
                  const SizedBox(width: 8.0),
                  _ActionButton(
                    icon: Icons.web,
                    label: 'Book',
                    onTap: onOpenForm!,
                    color: colorScheme.primary,
                  ),
                ],

                // Add to itinerary
                if (onAddToItinerary != null) ...[
                  const SizedBox(width: 8.0),
                  _ActionButton(
                    icon: Icons.add_to_photos,
                    label: 'Itinerary',
                    onTap: onAddToItinerary!,
                    color: colorScheme.secondary,
                  ),
                ],

                // Save/Favorite
                if (onToggleSave != null) ...[
                  const SizedBox(width: 8.0),
                  _ActionButton(
                    icon: isSaved ? Icons.favorite : Icons.favorite_border,
                    label: isSaved ? 'Saved' : 'Save',
                    onTap: onToggleSave!,
                    color: isSaved ? Colors.red : colorScheme.outline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 60.0,
        height: 60.0,
        child: CachedNetworkImage(
          imageUrl: event.banner!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _buildLocationText() {
    final parts = <String>[];

    // Add business ID as business name placeholder for now
    parts.add('Business ${event.businessId}');

    if (event.city != null && event.city!.isNotEmpty) {
      parts.add(event.city!);
    }

    return parts.join(' • ');
  }

  bool get _hasPromo {
    return (event.promoCode != null && event.promoCode!.isNotEmpty) ||
        (event.discountPct != null && event.discountPct! > 0);
  }

  Widget _buildPromoChip(BuildContext context) {
    final theme = Theme.of(context);

    String promoText = '';
    if (event.discountPct != null && event.discountPct! > 0) {
      promoText = '${event.discountPct!.toStringAsFixed(0)}% OFF';
    } else if (event.promoCode != null && event.promoCode!.isNotEmpty) {
      promoText = 'Code: ${event.promoCode!}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Text(
        promoText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.orange[800],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap to $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.0, color: color),
              const SizedBox(height: 2.0),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
