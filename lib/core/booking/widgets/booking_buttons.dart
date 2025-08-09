import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/core/booking/booking_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    final hasWa = phone != null && phone!.trim().isNotEmpty;
    final hasForm = bookingFormUrl != null && bookingFormUrl!.trim().isNotEmpty;

    if (!hasWa && !hasForm) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasWa)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.whatsapp),
              label: const Text('Book on WhatsApp'),
              onPressed: () async {
                final ok = await openWhatsApp(
                  phone: phone!.trim(),
                  message: _defaultMessage(),
                );
                if (ok) {
                  await BusinessAnalyticsService.instance.recordBookingWhatsApp(
                    businessId,
                  );
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
              onPressed: () async {
                final uri = buildFormUri(bookingFormUrl!.trim());
                final ok = await openUri(uri);
                if (ok) {
                  await BusinessAnalyticsService.instance.recordBookingForm(
                    businessId,
                  );
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
