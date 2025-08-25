import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ceylon/core/booking/booking_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingButtons extends StatelessWidget {
  final String businessId; // New required parameter for analytics
  final String? phone; // WhatsApp number (E.164 like +9477..., or any digits)
  final String? bookingFormUrl; // Google Form or any URL
  final String title; // Business or Event name
  final DateTime? when; // Optional date/time for events
  final String? contextNote; // Optional extra context

  const BookingButtons({
    super.key,
    required this.businessId, // Added required parameter
    required this.phone,
    required this.bookingFormUrl,
    required this.title,
    this.when,
    this.contextNote,
  });

  String _defaultMessage() {
    final buffer = StringBuffer();
    buffer.write('Hello! I would like to book/enquire about "$title"');
    if (when != null) {
      buffer.write(' on ${when!.toLocal().toString().split(".").first}');
    }
    if (contextNote != null && contextNote!.trim().isNotEmpty) {
      buffer.write('. $contextNote');
    }
    buffer.write('.');
    return buffer.toString();
  }

  void _recordBookingAnalytics(String type) {
    // Update the daily analytics for this business
    final today = DateTime.now();
    final dateString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection('analytics')
        .doc(businessId)
        .collection('daily')
        .doc(dateString)
        .set({
          'bookings': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final hasWa = phone != null && phone!.trim().isNotEmpty;
    final hasForm = bookingFormUrl != null && bookingFormUrl!.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    if (!hasWa && !hasForm) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasWa)
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(FontAwesomeIcons.whatsapp),
              label: const Text('Book on WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final ok = await openWhatsApp(
                  phone: phone!.trim(),
                  message: _defaultMessage(),
                );
                if (ok) {
                  _recordBookingAnalytics('whatsapp');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open WhatsApp.')),
                  );
                }
              },
            ),
          ),
        if (hasWa && hasForm) const SizedBox(width: 12),
        if (hasForm)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Booking Form'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final uri = buildFormUri(bookingFormUrl!.trim());
                final ok = await openUri(uri);
                if (ok) {
                  _recordBookingAnalytics('form');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open form.')),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
