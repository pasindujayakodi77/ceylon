import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FeedbackReason { tooFar, tooExpensive, closed, crowded, other }

class BusinessAnalyticsService {
  BusinessAnalyticsService._();
  static final instance = BusinessAnalyticsService._();

  final _db = FirebaseFirestore.instance;

  String _dayKey(DateTime d) {
    // yyyyMMdd in local time (you can switch to UTC if you prefer)
    return '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
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

  Future<void> submitFeedback({
    required String businessId,
    required FeedbackReason reason,
    String? note,
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
