import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'business_models.dart';

class BusinessRepository {
  BusinessRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  // ---- Business ----
  Future<Business?> getCurrentUserBusiness() async {
    final uid = _uid;
    if (uid == null) return null;
    final q = await _db
        .collection('businesses')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Business.fromDoc(q.docs.first);
  }

  Future<Business?> getBusinessById(String id) async {
    final doc = await _db.collection('businesses').doc(id).get();
    if (!doc.exists) return null;
    return Business.fromDoc(doc);
  }

  Future<void> updateBusinessProfile(
    String businessId, {
    String? name,
    String? description,
    String? photoUrl,
    bool? promotedActive,
    int? promotedRank,
    Map<String, dynamic>? extra,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (promotedActive != null) data['promotedActive'] = promotedActive;
    if (promotedRank != null) data['promotedRank'] = promotedRank;
    if (extra != null) data.addAll(extra);
    await _db.collection('businesses').doc(businessId).update(data);
  }

  Query<Map<String, dynamic>> promotedBusinessesQuery({int limit = 10}) {
    return _db
        .collection('businesses')
        .where('promotedActive', isEqualTo: true)
        .orderBy('promotedRank', descending: true)
        .limit(limit);
  }

  Future<void> requestVerification(String businessId, Map<String, dynamic> payload) async {
    final doc = _db
        .collection('businesses')
        .doc(businessId)
        .collection('verificationRequests')
        .doc(_uid); // idempotent per user
    await doc.set({
      ...payload,
      'userId': _uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---- Reviews ----
  Stream<List<Review>> streamReviews(String businessId, {int pageSize = 20}) {
    final ref = _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    return ref.snapshots().map(
          (s) => s.docs.map((d) => Review.fromDoc(d)).toList(),
        );
  }

  Future<void> submitReview(String businessId, {required String text, required int rating}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final ref = _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(uid);
    await ref.set({
      'userId': uid,
      'businessId': businessId,
      'text': text,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---- Feedback ----
  Future<void> submitFeedback(String businessId, {required String message, int? rating}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final ref = _db
        .collection('businesses')
        .doc(businessId)
        .collection('feedback')
        .doc(); // allow multiple feedback entries
    await ref.set({
      'userId': uid,
      'message': message,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- Events ----
  Future<List<BusinessEvent>> fetchEventsPage(
    String businessId, {
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .orderBy('startAt', descending: true)
        .limit(pageSize);

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    return snap.docs.map(BusinessEvent.fromDoc).toList();
  }

  Future<String> createEvent(String businessId, BusinessEvent evt) async {
    final ref = _db.collection('businesses').doc(businessId).collection('events').doc();
    await ref.set(evt.toJson());
    return ref.id;
  }

  Future<void> updateEvent(String businessId, String eventId, Map<String, dynamic> patch) async {
    await _db.collection('businesses').doc(businessId).collection('events').doc(eventId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
