import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripTemplateService {
  TripTemplateService._();
  static final instance = TripTemplateService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u.uid;
  }

  Future<List<Map<String, dynamic>>> listTemplates() async {
    final snap = await _db
        .collection('trip_templates')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<String> createTemplate({
    required String name,
    required String description,
    required List<Map<String, dynamic>> days,
  }) async {
    final ref = await _db.collection('trip_templates').add({
      'name': name,
      'description': description,
      'days': days,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<Map<String, dynamic>?> getTemplate(String id) async {
    final doc = await _db.collection('trip_templates').doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  Future<void> importTemplateToMyItinerary(
    Map<String, dynamic> template,
  ) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('itineraries')
        .add({
          'name': template['name'],
          'description': template['description'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    final itemsRef = ref.collection('items');
    final days = (template['days'] as List?) ?? [];
    for (final day in days) {
      await itemsRef.add({
        'type': 'template_day',
        'day': day['day'],
        'title': day['title'],
        'items': day['items'],
      });
    }
  }
}
