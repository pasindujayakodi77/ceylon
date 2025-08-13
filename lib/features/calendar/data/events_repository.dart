// FILE: lib/features/calendar/data/events_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_event.dart';

class EventsRepository {
  final FirebaseFirestore _firestore;

  EventsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch published events for a given month range
  Future<List<CalendarEvent>> fetchMonthEvents(
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    try {
      final query = await _firestore
          .collectionGroup('events')
          .where('published', isEqualTo: true)
          .where('startsAt', isGreaterThanOrEqualTo: monthStart)
          .where('startsAt', isLessThan: monthEnd)
          .orderBy('startsAt', descending: false)
          .get();

      return query.docs
          .map(
            (doc) => CalendarEvent.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Group events by day (truncated to yyyy-mm-dd)
  Future<Map<DateTime, List<CalendarEvent>>> groupByDay(
    List<CalendarEvent> events,
  ) async {
    final Map<DateTime, List<CalendarEvent>> grouped = {};

    for (final event in events) {
      // Truncate to date only (remove time component)
      final date = DateTime(
        event.startsAt.year,
        event.startsAt.month,
        event.startsAt.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(event);
      } else {
        grouped[date] = [event];
      }
    }

    return grouped;
  }

  /// Fetch minimal business metadata for display purposes
  Future<Map<String, String?>> fetchBusinessMeta(String businessId) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();

      if (!doc.exists) {
        return {
          'name': 'Unknown Business',
          'phone': null,
          'bookingFormUrl': null,
        };
      }

      final data = doc.data()!;
      return {
        'name': data['name'] as String? ?? 'Unknown Business',
        'phone': data['phone'] as String?,
        'bookingFormUrl': data['bookingFormUrl'] as String?,
      };
    } catch (e) {
      throw Exception('Failed to fetch business metadata: $e');
    }
  }

  /// Fetch events for a specific date
  Future<List<CalendarEvent>> fetchEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final query = await _firestore
          .collectionGroup('events')
          .where('published', isEqualTo: true)
          .where('startsAt', isGreaterThanOrEqualTo: startOfDay)
          .where('startsAt', isLessThanOrEqualTo: endOfDay)
          .orderBy('startsAt', descending: false)
          .get();

      return query.docs
          .map(
            (doc) => CalendarEvent.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events for date: $e');
    }
  }

  /// Fetch upcoming events (next N events from now)
  Future<List<CalendarEvent>> fetchUpcomingEvents({int limit = 10}) async {
    final now = DateTime.now();

    try {
      final query = await _firestore
          .collectionGroup('events')
          .where('published', isEqualTo: true)
          .where('startsAt', isGreaterThan: now)
          .orderBy('startsAt', descending: false)
          .limit(limit)
          .get();

      return query.docs
          .map(
            (doc) => CalendarEvent.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  /// Fetch events by tag/category
  Future<List<CalendarEvent>> fetchEventsByTag(
    String tag, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collectionGroup('events')
          .where('published', isEqualTo: true)
          .where('tags', arrayContains: tag);

      if (startDate != null) {
        query = query.where('startsAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('startsAt', isLessThan: endDate);
      }

      final result = await query
          .orderBy('startsAt', descending: false)
          .limit(limit)
          .get();

      return result.docs
          .map(
            (doc) => CalendarEvent.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events by tag: $e');
    }
  }
}
