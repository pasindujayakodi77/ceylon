// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Safer, batched client analytics.
/// Writes to `/businesses/{id}/metrics/{daily|hourly}/...`
class BusinessAnalyticsService {
  BusinessAnalyticsService._() {
    _restoreQueue();
    _autoFlushTimer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) => flushEventQueue(),
    );
  }
  static final instance = BusinessAnalyticsService._();

  final _db = FirebaseFirestore.instance;

  // Queue
  final List<_QueuedEvent> _queue = [];
  Timer? _autoFlushTimer;
  bool _flushInFlight = false;
  int _backoffSeconds = 2;

  Future<void> recordEvent(
    String businessId,
    String field, {
    DateTime? when,
  }) async {
    _queue.add(
      _QueuedEvent(
        businessId: businessId,
        field: field,
        when: when ?? DateTime.now().toUtc(),
      ),
    );
    await _persistQueue();
  }

  Future<void> recordCall(String businessId) =>
      recordEvent(businessId, 'cta_call');
  Future<void> recordDirections(String businessId) =>
      recordEvent(businessId, 'cta_directions');
  Future<void> recordWebsite(String businessId) =>
      recordEvent(businessId, 'cta_website');
  // Booking-specific helpers used across the UI
  Future<void> recordBookingWhatsApp(String businessId) =>
      recordEvent(businessId, 'booking_whatsapp');
  Future<void> recordBookingForm(String businessId) =>
      recordEvent(businessId, 'booking_form');

  Future<void> flushEventQueue() async {
    if (_flushInFlight || _queue.isEmpty) return;
    _flushInFlight = true;
    try {
      final batch = _db.batch();
      final nowUtc = DateTime.now().toUtc();
      for (final e in _queue) {
        final when = e.when ?? nowUtc;
        final dr = _dayRef(e.businessId, when);
        batch.set(dr, {
          'date': _dayString(when),
          e.field: FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final hr = _hourRef(e.businessId, when);
        batch.set(hr, {
          e.field: FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      _queue.clear();
      await _persistQueue();
      _backoffSeconds = 2; // reset
    } catch (e) {
      // exponential backoff
      _backoffSeconds = (_backoffSeconds * 2).clamp(2, 300);
      Future.delayed(Duration(seconds: _backoffSeconds));
    } finally {
      _flushInFlight = false;
    }
  }

  // ---- Helpers ----
  String _dayString(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>> _dayRef(
    String businessId,
    DateTime when,
  ) {
    final key = _dayString(when);
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days')
        .doc(key);
  }

  DocumentReference<Map<String, dynamic>> _hourRef(
    String businessId,
    DateTime when,
  ) {
    final dayKey = _dayString(when);
    final hour = when.toUtc().hour.toString().padLeft(2, '0');
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

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _queue.map((e) => e.toJson()).toList();
    await prefs.setString('business_analytics_queue', jsonEncode(list));
  }

  Future<void> _restoreQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('business_analytics_queue');
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _queue
        ..clear()
        ..addAll(list.map(_QueuedEvent.fromJson));
    } catch (_) {
      // ignore corrupted cache
      await prefs.remove('business_analytics_queue');
    }
  }
}

class _QueuedEvent {
  final String businessId;
  final String field;
  final DateTime? when;
  _QueuedEvent({required this.businessId, required this.field, this.when});

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'field': field,
    'when': when?.toIso8601String(),
  };

  factory _QueuedEvent.fromJson(Map<String, dynamic> j) => _QueuedEvent(
    businessId: j['businessId'] as String,
    field: j['field'] as String,
    when: j['when'] == null ? null : DateTime.tryParse(j['when'] as String),
  );
}
