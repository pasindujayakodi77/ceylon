// FILE: lib/features/business/data/business_analytics_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'business_models.dart';

/// Service for retrieving and analyzing business statistics.
///
/// Provides methods for streaming daily stats, computing summaries,
/// getting rating distributions, and finding top events.
class BusinessAnalyticsService {
  /// Creates a new [BusinessAnalyticsService] instance.
  ///
  /// Requires a [FirebaseFirestore] instance for data access.
  BusinessAnalyticsService({required FirebaseFirestore firestore})
    : _db = firestore;

  /// Factory constructor that creates an instance using the default Firestore instance.
  factory BusinessAnalyticsService.instance() =>
      BusinessAnalyticsService(firestore: FirebaseFirestore.instance);

  /// Singleton instance for easy access across the app.
  static final shared = BusinessAnalyticsService(
    firestore: FirebaseFirestore.instance,
  );

  final FirebaseFirestore _db;

  /// Collection path constants to avoid typos
  String get _businessesPath => 'businesses';
  String get _analyticsPath => 'analytics';
  String _dailyStatsPath(String businessId) =>
      '$_analyticsPath/$businessId/daily';
  String _eventsPath(String businessId) =>
      '$_businessesPath/$businessId/events';
  String _reviewsPath(String businessId) =>
      '$_businessesPath/$businessId/reviews';

  /// Formats a date as YYYY-MM-DD string.
  String _formatDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Streams daily statistics for a business over the specified number of days.
  ///
  /// Returns a stream of [DailyStat] lists ordered by date (oldest first).
  Stream<List<DailyStat>> streamDailyStats(String businessId, {int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    // Create a query for the date range
    final query = _db
        .collection(_dailyStatsPath(businessId))
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: _formatDateString(startDate),
        )
        .where(
          FieldPath.documentId,
          isLessThanOrEqualTo: _formatDateString(endDate),
        )
        .orderBy(FieldPath.documentId);

    return query.snapshots().map((snapshot) {
      // Convert documents to DailyStat objects
      final stats = snapshot.docs
          .map((doc) => DailyStat.fromDoc(doc, businessId: businessId))
          .toList();

      // Fill in any missing days with zero values
      final result = <DailyStat>[];
      DateTime current = startDate;

      while (!current.isAfter(endDate)) {
        final dateString = _formatDateString(current);

        // Find existing stat for this date or create a new one with zeros
        final existingStat = stats.firstWhereOrNull(
          (stat) => stat.date == dateString,
        );
        if (existingStat != null) {
          result.add(existingStat);
        } else {
          result.add(
            DailyStat(
              businessId: businessId,
              date: dateString,
              views: 0,
              bookmarks: 0,
              bookings: 0,
              updatedAt: Timestamp.now(),
            ),
          );
        }

        current = current.add(const Duration(days: 1));
      }

      return result;
    });
  }

  /// Computes summary statistics from a list of [DailyStat] objects.
  ///
  /// Returns a map containing total views, bookings, bookmarks,
  /// average rating, and review count.
  Future<Map<String, num>> computeSummary(
    List<DailyStat> stats,
    String businessId,
  ) async {
    // Calculate totals from daily stats
    final totalViews = stats.fold<int>(0, (total, stat) => total + stat.views);
    final totalBookmarks = stats.fold<int>(
      0,
      (total, stat) => total + stat.bookmarks,
    );
    final totalBookings = stats.fold<int>(
      0,
      (total, stat) => total + stat.bookings,
    );

    // Fetch the business for rating information
    final businessDoc = await _db
        .collection(_businessesPath)
        .doc(businessId)
        .get();
    double avgRating = 0.0;
    int reviewCount = 0;

    if (businessDoc.exists) {
      final data = businessDoc.data() ?? {};
      avgRating = (data['ratingAvg'] ?? 0.0).toDouble();
      reviewCount = (data['ratingCount'] ?? 0) as int;
    }

    return {
      'totalViews': totalViews,
      'totalBookmarks': totalBookmarks,
      'totalBookings': totalBookings,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
    };
  }

  /// Gets the distribution of ratings for a business.
  ///
  /// Returns a map with keys 1-5 representing star ratings and
  /// values representing the count of reviews with that rating.
  ///
  /// Can be directly used with chart libraries like fl_chart.
  Future<Map<int, int>> ratingDistribution(String businessId) async {
    // Initialize distribution with zeros
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    // Query for reviews
    final querySnapshot = await _db.collection(_reviewsPath(businessId)).get();

    // Count ratings
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] ?? 0) as int;
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// Gets the daily views data in a format ready for charts.
  ///
  /// Returns a list of (day, views) pairs that can be used directly with chart libraries.
  /// The `days` parameter controls how many days of data to include.
  Future<List<MapEntry<String, int>>> getViewsChartData(
    String businessId, {
    int days = 30,
  }) async {
    final statsStream = streamDailyStats(businessId, days: days);
    final statsList = await statsStream.first;

    // Create the data in the format expected by charts
    return statsList.map((stat) => MapEntry(stat.date, stat.views)).toList();
  }

  /// Gets the daily bookings data in a format ready for charts.
  ///
  /// Returns a list of (day, bookings) pairs that can be used directly with chart libraries.
  /// The `days` parameter controls how many days of data to include.
  Future<List<MapEntry<String, int>>> getBookingsChartData(
    String businessId, {
    int days = 30,
  }) async {
    final statsStream = streamDailyStats(businessId, days: days);
    final statsList = await statsStream.first;

    // Create the data in the format expected by charts
    return statsList.map((stat) => MapEntry(stat.date, stat.bookings)).toList();
  }

  /// Gets the daily bookmarks data in a format ready for charts.
  ///
  /// Returns a list of (day, bookmarks) pairs that can be used directly with chart libraries.
  /// The `days` parameter controls how many days of data to include.
  Future<List<MapEntry<String, int>>> getBookmarksChartData(
    String businessId, {
    int days = 30,
  }) async {
    final statsStream = streamDailyStats(businessId, days: days);
    final statsList = await statsStream.first;

    // Create the data in the format expected by charts
    return statsList
        .map((stat) => MapEntry(stat.date, stat.bookmarks))
        .toList();
  }

  /// Generates a CSV string from analytics data for export.
  ///
  /// Includes daily views, bookings, and bookmarks for the specified time period.
  Future<String> generateCsvExport(String businessId, {int days = 30}) async {
    final statsStream = streamDailyStats(businessId, days: days);
    final statsList = await statsStream.first;

    // CSV header
    final csvRows = <String>['Date,Views,Bookings,Bookmarks'];

    // Add data rows
    for (final stat in statsList) {
      csvRows.add(
        '${stat.date},${stat.views},${stat.bookings},${stat.bookmarks}',
      );
    }

    // Join rows with newlines
    return csvRows.join('\n');
  }

  /// Record an analytics event by enqueueing it in SharedPreferences.
  ///
  /// The queue is stored as a JSON array under the key `analytics_event_queue_v1`.
  /// Each entry is a map that contains at least the business id under key `b`.
  Future<void> recordEvent(String businessId, String eventName) async {
    const queueKey = 'analytics_event_queue_v1';

    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(queueKey);

    List<dynamic> arr = <dynamic>[];
    if (s != null) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List<dynamic>) arr = decoded;
      } catch (_) {
        arr = <dynamic>[];
      }
    }

    final entry = <String, dynamic>{
      'b': businessId,
      'e': eventName,
      't': DateTime.now().toIso8601String(),
    };

    // Add to the front so recent events are first (test only checks first element)
    arr.insert(0, entry);

    await prefs.setString(queueKey, jsonEncode(arr));
  }

  /// Finds the top events for a business based on bookings or interest.
  ///
  /// Returns a list of [BusinessEvent] objects sorted by booking count
  /// or interest level.
  Future<List<BusinessEvent>> topEvents(
    String businessId, {
    int limit = 5,
  }) async {
    // Get all events for this business
    final eventsSnapshot = await _db
        .collection(_eventsPath(businessId))
        .where('published', isEqualTo: true)
        .get();

    // Convert to BusinessEvent objects
    final events = eventsSnapshot.docs
        .map((doc) => BusinessEvent.fromDoc(doc))
        .toList();

    // If there are no events, return an empty list
    if (events.isEmpty) return [];

    // Get event bookings analytics data (from a collection group query for efficiency)
    final analyticsSnapshot = await _db
        .collectionGroup('eventBookings')
        .where('businessId', isEqualTo: businessId)
        .get();

    // Create a map of eventId -> booking count
    final bookingCounts = <String, int>{};
    for (var doc in analyticsSnapshot.docs) {
      final data = doc.data();
      final eventId = data['eventId'] as String?;
      if (eventId != null) {
        bookingCounts[eventId] = (bookingCounts[eventId] ?? 0) + 1;
      }
    }

    // Sort events by booking count (or start date as fallback for events with equal bookings)
    events.sort((a, b) {
      final aCount = bookingCounts[a.id] ?? 0;
      final bCount = bookingCounts[b.id] ?? 0;

      // First compare by booking count
      final countComparison = bCount.compareTo(aCount);
      if (countComparison != 0) return countComparison;

      // For events with equal booking counts, sort by start date (upcoming first)
      return a.startAt.compareTo(b.startAt);
    });

    // Return top events limited by the specified count
    return events.take(limit).toList();
  }
}
