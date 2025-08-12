import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreSeeder {
  static final _db = FirebaseFirestore.instance;

  /// Run everything once.
  static Future<void> seedAll() async {
    if (!kDebugMode) {
      debugPrint('Seeder is debug-only.');
      return;
    }
    await seedAttractions();
    await seedTripTemplates();
    await seedMyBusinessIfMissing();
  }

  /// Seed 10 popular Sri Lanka attractions (idempotent).
  static Future<void> seedAttractions() async {
    final List<Map<String, dynamic>> list = [
      {
        'id': 'sigiriya',
        'name': 'Sigiriya Rock Fortress',
        'city': 'Sigiriya',
        'category': 'history',
        'tags': ['history', 'view', 'hike'],
        'photo': 'https://picsum.photos/seed/sigiriya/800/500',
        'location': {'lat': 7.9569, 'lng': 80.7599},
        'description':
            'Ancient rock citadel with frescoes and panoramic views.',
        'avg_rating': 4.8,
        'review_count': 1200,
        'est_cost': 9000,
      },
      {
        'id': 'galle_fort',
        'name': 'Galle Fort',
        'city': 'Galle',
        'category': 'culture',
        'tags': ['culture', 'sunset', 'walk'],
        'photo': 'https://picsum.photos/seed/galle/800/500',
        'location': {'lat': 6.0260, 'lng': 80.2170},
        'description': 'UNESCO Dutch fort, cafes and sea walls.',
        'avg_rating': 4.6,
        'review_count': 980,
        'est_cost': 0,
      },
      {
        'id': 'nine_arch',
        'name': 'Nine Arches Bridge',
        'city': 'Ella',
        'category': 'view',
        'tags': ['train', 'photo', 'hike'],
        'photo': 'https://picsum.photos/seed/ninearch/800/500',
        'location': {'lat': 6.8761, 'lng': 81.0606},
        'description': 'Iconic stone bridge with scenic train shots.',
        'avg_rating': 4.7,
        'review_count': 860,
        'est_cost': 0,
      },
      {
        'id': 'temple_tooth',
        'name': 'Temple of the Tooth',
        'city': 'Kandy',
        'category': 'religious',
        'tags': ['culture', 'history'],
        'photo': 'https://picsum.photos/seed/kandy/800/500',
        'location': {'lat': 7.2949, 'lng': 80.6413},
        'description': 'Buddhist temple housing the sacred tooth relic.',
        'avg_rating': 4.5,
        'review_count': 1100,
        'est_cost': 3000,
      },
      {
        'id': 'mirissa',
        'name': 'Mirissa Beach',
        'city': 'Mirissa',
        'category': 'beach',
        'tags': ['beach', 'sunset', 'surf'],
        'photo': 'https://picsum.photos/seed/mirissa/800/500',
        'location': {'lat': 5.9485, 'lng': 80.4544},
        'description': 'Chilled beach, whale watching nearby.',
        'avg_rating': 4.6,
        'review_count': 740,
        'est_cost': 0,
      },
      {
        'id': 'yala',
        'name': 'Yala National Park',
        'city': 'Tissamaharama',
        'category': 'wildlife',
        'tags': ['safari', 'wildlife'],
        'photo': 'https://picsum.photos/seed/yala/800/500',
        'location': {'lat': 6.3667, 'lng': 81.5167},
        'description': 'Leopards, elephants and lagoons on safari.',
        'avg_rating': 4.4,
        'review_count': 650,
        'est_cost': 15000,
      },
      {
        'id': 'little_adams_peak',
        'name': "Little Adam's Peak",
        'city': 'Ella',
        'category': 'hike',
        'tags': ['hike', 'view'],
        'photo': 'https://picsum.photos/seed/lap/800/500',
        'location': {'lat': 6.8667, 'lng': 81.0596},
        'description': 'Short hike with big views.',
        'avg_rating': 4.8,
        'review_count': 900,
        'est_cost': 0,
      },
      {
        'id': 'dambulla',
        'name': 'Dambulla Cave Temple',
        'city': 'Dambulla',
        'category': 'history',
        'tags': ['caves', 'art'],
        'photo': 'https://picsum.photos/seed/dambulla/800/500',
        'location': {'lat': 7.8568, 'lng': 80.6495},
        'description': 'Rock cave complex with ancient murals.',
        'avg_rating': 4.5,
        'review_count': 500,
        'est_cost': 4000,
      },
      {
        'id': 'horton_plains',
        'name': "Horton Plains / World's End",
        'city': 'Nuwara Eliya',
        'category': 'hike',
        'tags': ['hike', 'view', 'nature'],
        'photo': 'https://picsum.photos/seed/horton/800/500',
        'location': {'lat': 6.8029, 'lng': 80.7998},
        'description': 'Plateau trek to dramatic cliff drop.',
        'avg_rating': 4.6,
        'review_count': 420,
        'est_cost': 8000,
      },
      {
        'id': 'colombo_museum',
        'name': 'Colombo National Museum',
        'city': 'Colombo',
        'category': 'museum',
        'tags': ['history', 'museum'],
        'photo': 'https://picsum.photos/seed/museum/800/500',
        'location': {'lat': 6.9061, 'lng': 79.8607},
        'description': 'Largest museum in Sri Lanka.',
        'avg_rating': 4.3,
        'review_count': 300,
        'est_cost': 1500,
      },
    ];

    for (final m in list) {
      final id = m['id'] as String;
      await _db.collection('attractions').doc(id).set({
        ...m,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Two demo templates users can import.
  static Future<void> seedTripTemplates() async {
    final templates = [
      {
        'name': '7 Days Highlights (Central + South)',
        'description': 'Kandy → Ella → Yala → Galle',
        'days': [
          {
            'day': 1,
            'title': 'Kandy City',
            'items': ['Temple of the Tooth', 'Kandy Lake Walk'],
          },
          {
            'day': 2,
            'title': 'Train to Ella',
            'items': ['Nine Arches Bridge', "Little Adam's Peak"],
          },
          {
            'day': 3,
            'title': 'Ella Views',
            'items': ['Ella Rock', 'Ravana Falls'],
          },
          {
            'day': 4,
            'title': 'Yala Safari',
            'items': ['Half‑day safari'],
          },
          {
            'day': 5,
            'title': 'Galle Fort',
            'items': ['Ramparts walk', 'Sunset'],
          },
          {
            'day': 6,
            'title': 'Beaches',
            'items': ['Unawatuna', 'Mirissa'],
          },
          {
            'day': 7,
            'title': 'Colombo',
            'items': ['National Museum', 'Galle Face Green'],
          },
        ],
      },
      {
        'name': 'Long Weekend Colombo → Galle',
        'description': 'Easy coastal getaway',
        'days': [
          {
            'day': 1,
            'title': 'Colombo',
            'items': ['National Museum'],
          },
          {
            'day': 2,
            'title': 'Galle Fort + Unawatuna',
            'items': ['Ramparts', 'Beach time'],
          },
          {
            'day': 3,
            'title': 'Mirissa',
            'items': ['Whale watching (seasonal)'],
          },
        ],
      },
    ];

    for (final t in templates) {
      await _db.collection('trip_templates').add({
        ...t,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
    }
  }

  /// Create a business for the current user if missing (lets you test dashboard/analytics).
  static Future<void> seedMyBusinessIfMissing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final existing = await _db
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _db.collection('businesses').add({
      'ownerId': uid,
      'name': 'My Demo Tour',
      'description': 'Sample listing seeded from Dev Tools.',
      'category': 'tour',
      'phone': '+94770000000',
      'photo': '',
      'promoted': false,
      'promotedWeight': 10,
      'promotedUntil': null,
      'verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
