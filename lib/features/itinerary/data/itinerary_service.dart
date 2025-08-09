import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItineraryService {
  ItineraryService._();
  static final instance = ItineraryService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('Not signed in');
    }
    return u.uid;
  }

  /// Returns the user's itineraries ordered by createdAt desc.
  Future<List<Map<String, dynamic>>> listItineraries() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('itineraries')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Creates a new itinerary with a name; returns the new document id.
  Future<String> createItinerary(String name) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('itineraries')
        .add({
          'name': name.trim().isEmpty ? 'My Trip' : name.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    return ref.id;
  }

  /// Adds a holiday item to an itinerary's items subcollection.
  Future<void> addHolidayItem({
    required String itineraryId,
    required DateTime date,
    required String countryCode,
    required String holidayName,
    String? note,
  }) async {
    final itemsRef = _db
        .collection('users')
        .doc(_uid)
        .collection('itineraries')
        .doc(itineraryId)
        .collection('items');

    await itemsRef.add({
      'type': 'holiday',
      'name': holidayName,
      'country': countryCode,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // touch itinerary updatedAt
    await _db
        .collection('users')
        .doc(_uid)
        .collection('itineraries')
        .doc(itineraryId)
        .set({
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
