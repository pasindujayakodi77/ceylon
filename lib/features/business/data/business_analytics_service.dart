import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessAnalyticsService {
  BusinessAnalyticsService._();
  static final instance = BusinessAnalyticsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// YYYY-MM-DD using device local time
  String get todayId {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Increment daily visitors for the business
  Future<void> recordVisitor(String businessId) async {
    final dayId = todayId;
    final doc = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics_daily')
        .doc(dayId);
    await doc.set({
      'visitors': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Increment favorites_added for the day (when someone favorites this business)
  Future<void> recordFavoriteAdded(String businessId) async {
    final dayId = todayId;
    final doc = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics_daily')
        .doc(dayId);
    await doc.set({
      'favorites_added': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// (Optional) decrement a daily counter if you allow unfavorite to reduce stats
  Future<void> recordFavoriteRemoved(String businessId) async {
    final dayId = todayId;
    final doc = _db
        .collection('businesses')
        .doc(businessId)
        .collection('metrics_daily')
        .doc(dayId);
    await doc.set({
      'favorites_added': FieldValue.increment(-1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Recompute avg_rating & review_count from reviews subcollection and cache on the business doc
  Future<void> recomputeAndCacheRating(String businessId) async {
    final reviewsSnap = await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .get();

    if (reviewsSnap.docs.isEmpty) {
      await _db.collection('businesses').doc(businessId).set({
        'avg_rating': null,
        'review_count': 0,
        'ratings_cached_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    double sum = 0;
    int count = 0;
    for (final doc in reviewsSnap.docs) {
      final rating = (doc.data()['rating'] as num?)?.toDouble();
      if (rating != null) {
        sum += rating;
        count++;
      }
    }
    final avg = count == 0
        ? null
        : double.parse((sum / count).toStringAsFixed(2));

    await _db.collection('businesses').doc(businessId).set({
      'avg_rating': avg,
      'review_count': count,
      'ratings_cached_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
