import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeedbackReason { tooFar, tooExpensive, closed, crowded, other }

// Simple in-memory queued event model used by the batching helper below.
class _QueuedEvent {
  final String businessId;
  final String field;
  final DateTime? when;

  _QueuedEvent({required this.businessId, required this.field, this.when});
}

class BusinessAnalyticsService {
  BusinessAnalyticsService._() {
    // restore persisted queue and start auto-flush
    _restoreQueue();
    _autoFlushTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => flushEventQueue(),
    );
  }
  static final instance = BusinessAnalyticsService._();

  final _db = FirebaseFirestore.instance;

  String _dayKey(DateTime d) {
    // yyyyMMdd in local time (you can switch to UTC if you prefer)
    return '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  String _hourKey(DateTime d) {
    // yyyyMMddHH
    return '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}${d.hour.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>> _dayRef(
    String businessId,
    DateTime when,
  ) {
    final key = _dayKey(when);
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days')
        .doc(key);
  }

  Future<void> _inc(String businessId, String field, {DateTime? when}) async {
    final now = when ?? DateTime.now();
    final ref = _dayRef(businessId, now);
    await ref.set({
      'date':
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      field: FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _hourRef(
    String businessId,
    DateTime when,
  ) {
    final dayKey = _dayKey(when);
    final hour = when.hour.toString().padLeft(2, '0');
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('hourly')
        .collection('days')
        .doc(dayKey)
        .collection('hours')
        .doc(hour);
  }

  /// Public logging API
  Future<void> recordVisitor(String businessId) => _inc(businessId, 'views');

  Future<void> recordFavoriteAdded(String businessId) =>
      _inc(businessId, 'favorites_added');
  Future<void> recordFavoriteRemoved(String businessId) =>
      _inc(businessId, 'favorites_removed');

  Future<void> recordBookingWhatsApp(String businessId) =>
      _inc(businessId, 'bookings_whatsapp');
  Future<void> recordBookingForm(String businessId) =>
      _inc(businessId, 'bookings_form');

  /// Generic event recorder for arbitrary named events. This lets the app
  /// log CTA clicks or custom metrics without adding a dedicated method.
  Future<void> recordEvent(
    String businessId,
    String eventName, {
    DateTime? when,
    Map<String, dynamic>? meta,
  }) async {
    // normalize to field name safe string
    final field = eventName
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .toLowerCase();
    // short-circuit to queue for batching
    _enqueueEvent(
      _QueuedEvent(businessId: businessId, field: field, when: when),
    );
  }

  // Convenience wrappers for common CTAs
  Future<void> recordCall(String businessId) =>
      recordEvent(businessId, 'cta_call');
  Future<void> recordDirections(String businessId) =>
      recordEvent(businessId, 'cta_directions');
  Future<void> recordWebsite(String businessId) =>
      recordEvent(businessId, 'cta_website');

  // --- Simple in-memory batching queue ---
  final List<_QueuedEvent> _eventQueue = [];
  Timer? _autoFlushTimer;
  bool _isFlushing = false;

  void _enqueueEvent(_QueuedEvent e) {
    _eventQueue.add(e);
    // start auto-flush if not already running
    _persistQueue();
    _autoFlushTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => flushEventQueue(),
    );
    // if the queue grows large, flush immediately
    if (_eventQueue.length >= 50) {
      flushEventQueue();
    }
  }

  /// Flush queued events to Firestore in batched increments.
  Future<void> flushEventQueue() async {
    if (_isFlushing) return;
    if (_eventQueue.isEmpty) return;
    _isFlushing = true;

    final now = DateTime.now();
    final events = List<_QueuedEvent>.from(_eventQueue);

    // group counts by (businessId, dayKey, field) and also by hour
    final Map<String, int> dailyCounts = {};
    final Map<String, int> hourlyCounts = {};
    for (final e in events) {
      final when = e.when ?? now;
      final dKey = '${e.businessId}::${_dayKey(when)}::${e.field}';
      dailyCounts[dKey] = (dailyCounts[dKey] ?? 0) + 1;

      final hKey = '${e.businessId}::${_hourKey(when)}::${e.field}';
      hourlyCounts[hKey] = (hourlyCounts[hKey] ?? 0) + 1;
    }

    // prepare batched writes
    final batch = _db.batch();
    for (final entry in dailyCounts.entries) {
      final parts = entry.key.split('::');
      final businessId = parts[0];
      final dayKey = parts[1];
      final field = parts[2];
      final when = DateTime(
        int.parse(dayKey.substring(0, 4)),
        int.parse(dayKey.substring(4, 6)),
        int.parse(dayKey.substring(6, 8)),
      );
      final ref = _dayRef(businessId, when);
      batch.set(ref, {
        'date':
            '${when.year.toString().padLeft(4, '0')}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}',
        field: FieldValue.increment(entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final entry in hourlyCounts.entries) {
      final parts = entry.key.split('::');
      final businessId = parts[0];
      final hourKey = parts[1];
      final field = parts[2];
      final dt = DateTime(
        int.parse(hourKey.substring(0, 4)),
        int.parse(hourKey.substring(4, 6)),
        int.parse(hourKey.substring(6, 8)),
        int.parse(hourKey.substring(8, 10)),
      );
      final ref = _hourRef(businessId, dt);
      batch.set(ref, {
        'date':
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
        'hour': dt.hour,
        field: FieldValue.increment(entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Persist and clear queue before commit to avoid double-applying on retry
    _eventQueue.clear();
    await _persistQueue();

    try {
      await batch.commit();
    } catch (e) {
      // Re-enqueue on failure and schedule a retry
      // ignore: avoid_print
      print('Failed to flush business analytics queue: $e');
      _eventQueue.addAll(events);
      await _persistQueue();
      // schedule retry after delay
      Future.delayed(const Duration(seconds: 30), () => flushEventQueue());
    } finally {
      _isFlushing = false;
    }
  }

  // Persist queued events to SharedPreferences as small JSON
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _eventQueue
          .map(
            (e) => {
              'b': e.businessId,
              'f': e.field,
              't': e.when?.toIso8601String(),
            },
          )
          .toList();
      await prefs.setString('analytics_event_queue_v1', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _restoreQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('analytics_event_queue_v1');
      if (s == null || s.isEmpty) return;
      final arr = jsonDecode(s) as List<dynamic>;
      for (final el in arr) {
        final m = el as Map<String, dynamic>;
        final when = m['t'] != null
            ? DateTime.tryParse(m['t'] as String)
            : null;
        _eventQueue.add(
          _QueuedEvent(
            businessId: m['b'] as String,
            field: m['f'] as String,
            when: when,
          ),
        );
      }
    } catch (_) {}
  }

  /// Submit a batched payload to a server-side queue collection so a Cloud Function
  /// can process it server-side. This reduces client write load in busy apps.
  Future<void> submitBatchToServer(Map<String, dynamic> payload) async {
    final ref = _db.collection('analytics_batches').doc();
    await ref.set({
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
      'source': FirebaseAuth.instance.currentUser?.uid ?? 'client',
    });
  }

  /// Lightweight health check: attempt a small write to meta/health_check.
  Future<bool> healthCheck() async {
    try {
      await _db.collection('meta').doc('health_check').set({
        'ping': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Return aggregated totals for fields across a date range (inclusive).
  /// If start/end are omitted the last [days] days are used.
  Future<Map<String, num>> getAggregates(
    String businessId, {
    DateTime? start,
    DateTime? end,
    int days = 30,
  }) async {
    final now = DateTime.now();
    final endDate = end ?? now;
    final startDate = start ?? now.subtract(Duration(days: days - 1));

    final col = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days');

    final snap = await col.get();
    final Map<String, num> totals = {};
    for (final d in snap.docs) {
      final id = d.id;
      // parse id yyyyMMdd
      if (id.length != 8) continue;
      final dt = DateTime(
        int.parse(id.substring(0, 4)),
        int.parse(id.substring(4, 6)),
        int.parse(id.substring(6, 8)),
      );
      if (dt.isBefore(startDate) || dt.isAfter(endDate)) continue;
      final data = d.data();
      data.forEach((k, v) {
        if (k == 'date' || k == 'updatedAt') return;
        if (v is num) {
          totals[k] = (totals[k] ?? 0) + v;
        }
      });
    }
    return totals;
  }

  /// Returns hourly aggregates for a single date (local) as a map hour->counts map
  Future<Map<int, Map<String, num>>> getHourlyAggregates(
    String businessId,
    DateTime date,
  ) async {
    final dayKey = _dayKey(date);
    final col = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('hourly')
        .collection('days')
        .doc(dayKey)
        .collection('hours');
    final snap = await col.get();
    final Map<int, Map<String, num>> out = {};
    for (final d in snap.docs) {
      final m = d.data();
      final hour = (m['hour'] is int)
          ? m['hour'] as int
          : int.tryParse(d.id) ?? 0;
      final Map<String, num> counts = {};
      m.forEach((k, v) {
        if (k == 'date' || k == 'hour' || k == 'updatedAt') return;
        if (v is num) counts[k] = v;
      });
      out[hour] = counts;
    }
    return out;
  }

  /// Returns a time series (daily) for a specific field
  Future<Map<String, num>> getTimeSeries(
    String businessId,
    String field, {
    DateTime? start,
    DateTime? end,
    int days = 30,
  }) async {
    final Map<String, num> series = {};
    final now = DateTime.now();
    final endDate = end ?? now;
    final startDate = start ?? now.subtract(Duration(days: days - 1));
    final col = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days');
    final snap = await col.get();
    for (final d in snap.docs) {
      final id = d.id;
      if (id.length != 8) continue;
      final dt = DateTime(
        int.parse(id.substring(0, 4)),
        int.parse(id.substring(4, 6)),
        int.parse(id.substring(6, 8)),
      );
      if (dt.isBefore(startDate) || dt.isAfter(endDate)) continue;
      final m = d.data();
      final val = (m[field] is num) ? m[field] as num : 0;
      series[id] = val;
    }
    return series;
  }

  /// Export analytics for a business to CSV. Returns CSV string.
  Future<String> exportCsv(String businessId, {int days = 30}) async {
    final rows = await loadLastDays(businessId, days: days);
    if (rows.isEmpty) return '';
    final headers = <String>{};
    for (final r in rows) {
      headers.addAll(r.keys.where((k) => k != 'id'));
    }
    final headerList = ['id', ...headers];
    String escapeCsv(String s) {
      final needsQuote =
          s.contains('"') ||
          s.contains(',') ||
          s.contains('\n') ||
          s.contains('\r');
      final escaped = s.replaceAll('"', '""');
      return needsQuote ? '"$escaped"' : escaped;
    }

    final buf = StringBuffer();
    // write header row (quote headers only if needed)
    buf.writeln(headerList.map((h) => escapeCsv(h)).join(','));
    for (final r in rows) {
      final values = headerList.map((h) {
        final v = (r[h] ?? '').toString();
        return escapeCsv(v);
      }).toList();
      buf.writeln(values.join(','));
    }
    return buf.toString();
  }

  /// Export analytics as JSON structure (list of per-day maps)
  Future<String> exportJson(String businessId, {int days = 30}) async {
    final rows = await loadLastDays(businessId, days: days);
    return jsonEncode(rows);
  }

  Future<void> submitFeedback({
    required String businessId,
    required FeedbackReason reason,
    String? note,
    int? rating, // 1-5
    int? nps, // 0-10
    List<String>? categories,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final rKey = switch (reason) {
      FeedbackReason.tooFar => 'feedback_too_far',
      FeedbackReason.tooExpensive => 'feedback_too_expensive',
      FeedbackReason.closed => 'feedback_closed',
      FeedbackReason.crowded => 'feedback_crowded',
      FeedbackReason.other => 'feedback_other',
    };

    // 1) increment daily bucket
    await _inc(businessId, rKey);

    // 1b) optional rating/nps/category buckets
    if (rating != null && rating >= 1 && rating <= 5) {
      await _inc(businessId, 'rating_$rating');
    }
    if (nps != null && nps >= 0 && nps <= 10) {
      await _inc(businessId, 'nps_${(nps ~/ 1).toString()}');
    }
    if (categories != null && categories.isNotEmpty) {
      for (final c in categories) {
        final key =
            'feedback_cat_${c.replaceAll(RegExp(r'[^a-z0-9_]'), '_').toLowerCase()}';
        await _inc(businessId, key);
      }
    }

    // 2) write raw feedback doc
    final ref = _db
        .collection('businesses')
        .doc(businessId)
        .collection('feedback')
        .doc();
    await ref.set({
      'byUid': uid,
      'reason': rKey,
      'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Load last N days of analytics for the business owner.
  Future<List<Map<String, dynamic>>> loadLastDays(
    String businessId, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final col = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days');

    // We fetch all and filter client-side by date key to avoid index complexity.
    final snap = await col.get();
    final list = snap.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();

    // filter to last N days only
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final keys = <String>{};
    for (int i = 0; i < days; i++) {
      keys.add(
        key(
          DateTime(start.year, start.month, start.day).add(Duration(days: i)),
        ),
      );
    }

    final filtered =
        list.where((m) => keys.contains(m['id'] as String)).toList()
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    return filtered;
  }

  /// Owner’s business id lookup by owner uid
  Future<String?> myBusinessId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }
}
