// FILE: lib/features/business/data/business_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'business_models.dart';

/// Repository that provides access to business data in Firestore.
///
/// Acts as a single source of truth for all business-related data operations.
class BusinessRepository {
  /// Creates a new [BusinessRepository] instance.
  ///
  /// Requires a [FirebaseFirestore] instance and [FirebaseAuth] for user context.
  BusinessRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _db = firestore,
       _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // Private collection paths to avoid typos
  String get _businessesPath => 'businesses';
  String _eventsPath(String businessId) =>
      '$_businessesPath/$businessId/events';
  String _reviewsPath(String businessId) =>
      '$_businessesPath/$businessId/reviews';
  String _feedbackPath(String businessId) =>
      '$_businessesPath/$businessId/feedback';
  String get _analyticsPath => 'analytics';
  String _dailyStatsPath(String businessId) =>
      '$_analyticsPath/$businessId/daily';

  /// Gets the current user's ID or null if not signed in.
  String? get _uid => _auth.currentUser?.uid;

  /// Fetches a business by its ID.
  ///
  /// Returns null if the business doesn't exist.
  Future<Business?> getBusiness(String id) async {
    final docSnapshot = await _db.collection(_businessesPath).doc(id).get();
    if (!docSnapshot.exists) return null;
    return Business.fromDoc(docSnapshot);
  }

  /// Provides a real-time stream of a business by its ID.
  Stream<Business?> streamBusiness(String id) {
    return _db
        .collection(_businessesPath)
        .doc(id)
        .snapshots()
        .map((snapshot) => snapshot.exists ? Business.fromDoc(snapshot) : null);
  }

  /// Creates a new business or updates an existing one.
  Future<void> upsertBusiness(Business business) async {
    await _db.collection(_businessesPath).doc(business.id).set({
      ...business.toJson(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Lists promoted businesses with optional filtering for active promotions only.
  ///
  /// Supports pagination through [startAfterDocument].
  Future<List<Business>> listPromoted({
    int limit = 10,
    bool onlyActive = true,
    DocumentSnapshot? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(_businessesPath)
        .where('promoted', isEqualTo: true)
        .orderBy('promotedWeight', descending: true)
        .limit(limit);

    if (onlyActive) {
      // If we only want active promotions, filter by promotedUntil > now
      final now = Timestamp.now();
      query = query.where('promotedUntil', isGreaterThan: now);
    }

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => Business.fromDoc(doc)).toList();
  }

  /// Lists businesses owned by a specific user.
  ///
  /// Supports pagination through [startAfterDocument].
  Future<List<Business>> listOwned(
    String ownerId, {
    int limit = 10,
    DocumentSnapshot? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(_businessesPath)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updated_at', descending: true)
        .limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => Business.fromDoc(doc)).toList();
  }

  /// Provides a real-time stream of events for a specific business.
  ///
  /// Supports pagination through [startAfterDocument].
  Stream<List<BusinessEvent>> streamEvents(
    String businessId, {
    int limit = 20,
    DocumentSnapshot? startAfterDocument,
    bool includeUnpublished = false,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(_eventsPath(businessId))
        .orderBy('startAt')
        .limit(limit);

    if (!includeUnpublished) {
      query = query.where('published', isEqualTo: true);
    }

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => BusinessEvent.fromDoc(doc)).toList(),
    );
  }

  /// Creates a new event or updates an existing one.
  Future<String> upsertEvent(String businessId, BusinessEvent event) async {
    final String eventId = event.id.isEmpty
        ? _db.collection(_eventsPath(businessId)).doc().id
        : event.id;

    final updatedEvent = event.copyWith(id: eventId, businessId: businessId);

    await _db
        .collection(_eventsPath(businessId))
        .doc(eventId)
        .set(updatedEvent.toJson(), SetOptions(merge: true));

    return eventId;
  }

  /// Deletes an event.
  Future<void> deleteEvent(String businessId, String eventId) async {
    await _db.collection(_eventsPath(businessId)).doc(eventId).delete();
  }

  /// Provides a real-time stream of reviews for a specific business.
  ///
  /// Supports pagination through [startAfterDocument].
  Stream<List<BusinessReview>> streamReviews(
    String businessId, {
    int limit = 50,
    DocumentSnapshot? startAfterDocument,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(_reviewsPath(businessId))
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => BusinessReview.fromDoc(doc)).toList(),
    );
  }

  /// Adds a reply to a review.
  Future<void> replyToReview(
    String businessId,
    String reviewId,
    String replyText,
  ) async {
    await _db.collection(_reviewsPath(businessId)).doc(reviewId).update({
      'ownerReply': replyText,
      'ownerReplyAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adds feedback for a business.
  Future<String> addFeedback(
    String businessId,
    BusinessFeedback feedback,
  ) async {
    final String feedbackId = feedback.id.isEmpty
        ? _db.collection(_feedbackPath(businessId)).doc().id
        : feedback.id;

    final updatedFeedback = feedback.copyWith(
      id: feedbackId,
      businessId: businessId,
    );

    await _db
        .collection(_feedbackPath(businessId))
        .doc(feedbackId)
        .set(updatedFeedback.toJson(), SetOptions(merge: true));

    return feedbackId;
  }

  /// Updates promotion details for a business.
  Future<void> updatePromotion(
    String businessId, {
    bool? promoted,
    int? promotedWeight,
    Timestamp? promotedUntil,
  }) async {
    final Map<String, dynamic> updateData = {
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (promoted != null) updateData['promoted'] = promoted;
    if (promotedWeight != null) updateData['promotedWeight'] = promotedWeight;
    if (promotedUntil != null) updateData['promotedUntil'] = promotedUntil;

    await _db.collection(_businessesPath).doc(businessId).update(updateData);
  }

  /// Submits a verification request for a business.
  Future<void> requestVerification(
    String businessId, {
    required String docsUrl,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');

    await _db
        .collection(_businessesPath)
        .doc(businessId)
        .collection('verificationRequests')
        .doc(uid) // One request per user
        .set({
          'userId': uid,
          'businessId': businessId,
          'docsUrl': docsUrl,
          'note': note,
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Update business verification status
    await _db.collection(_businessesPath).doc(businessId).update({
      'verificationStatus': 'pending',
    });
  }

  /// Checks if a business has a pending verification request.
  Future<bool> hasVerificationRequest(String businessId) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');

    final request = await _db
        .collection(_businessesPath)
        .doc(businessId)
        .collection('verificationRequests')
        .doc(uid)
        .get();

    return request.exists && request.data()?['status'] == 'pending';
  }

  /// Stream the verification status for a business
  Stream<String> streamVerificationStatus(String businessId) {
    return _db.collection(_businessesPath).doc(businessId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) return 'none';

      if (data['verified'] == true) return 'approved';
      return data['verificationStatus'] as String? ?? 'none';
    });
  }

  /// Retrieves daily statistics for a business.
  ///
  /// [date] should be in YYYY-MM-DD format.
  Future<DailyStat?> getDailyStat(String businessId, String date) async {
    final docRef = _db.collection(_dailyStatsPath(businessId)).doc(date);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return null;

    return DailyStat.fromDoc(docSnapshot, businessId: businessId);
  }
}
