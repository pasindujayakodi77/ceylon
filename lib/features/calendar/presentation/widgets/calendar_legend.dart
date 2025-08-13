// FILE: lib/features/calendar/presentation/widgets/calendar_legend.dart

import 'package:flutter/material.dart';

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define colors that adapt to theme
    final holidayColor = colorScheme.primary;
    final eventColor = colorScheme.secondary;

    return Semantics(
      label: 'Calendar legend',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(color: holidayColor, label: 'Holiday'),
            const SizedBox(width: 24.0),
            _LegendItem(color: eventColor, label: 'Event'),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label indicator',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6.0),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
