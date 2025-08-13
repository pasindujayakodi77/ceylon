// FILE: lib/features/calendar/data/calendar_event.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarEvent {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String? banner;
  final String? promoCode;
  final double? discountPct;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> tags;
  final String? city;

  const CalendarEvent({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    this.banner,
    this.promoCode,
    this.discountPct,
    required this.startsAt,
    required this.endsAt,
    this.tags = const [],
    this.city,
  });

  factory CalendarEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CalendarEvent(
      id: doc.id,
      businessId: data['businessId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      banner: data['banner'] as String?,
      promoCode: data['promoCode'] as String?,
      discountPct: (data['discountPct'] as num?)?.toDouble(),
      startsAt: (data['startsAt'] as Timestamp).toDate(),
      endsAt: (data['endsAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      city: data['city'] as String?,
    );
  }

  /// Returns formatted time range (e.g., "2:00 PM - 6:00 PM")
  String get formattedTimeRange {
    final formatter = DateFormat('h:mm a');
    return '${formatter.format(startsAt)} - ${formatter.format(endsAt)}';
  }

  /// Returns formatted date range if multi-day event
  String get formattedDateRange {
    final dateFormatter = DateFormat('MMM d');
    if (isSameDay(startsAt, endsAt)) {
      return dateFormatter.format(startsAt);
    }
    return '${dateFormatter.format(startsAt)} - ${dateFormatter.format(endsAt)}';
  }

  /// Check if event spans multiple days
  bool get isMultiDay => !isSameDay(startsAt, endsAt);

  /// Duration of the event
  Duration get duration => endsAt.difference(startsAt);

  /// Check if event is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  /// Check if event is upcoming (starts in the future)
  bool get isUpcoming => DateTime.now().isBefore(startsAt);

  /// Helper to check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, startsAt: $startsAt, endsAt: $endsAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
