import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class AttractionsImporter {
  AttractionsImporter._();
  static final _db = FirebaseFirestore.instance;

  /// Import from assets/json/attractions_seed.json
  static Future<int> importFromAsset([
    String path = 'assets/json/attractions_seed.json',
  ]) async {
    final jsonStr = await rootBundle.loadString(path);
    final parsed = json.decode(jsonStr);

    final List items = (parsed is Map && parsed['items'] is List)
        ? parsed['items'] as List
        : (parsed as List);

    int ok = 0;
    for (final raw in items) {
      if (raw is! Map) continue;

      // Prefer provided id. If missing, slug from name.
      String id = (raw['id'] ?? '').toString().trim();
      if (id.isEmpty) {
        id = _slug((raw['name'] ?? 'place').toString());
      }

      final data = {
        'name': raw['name'],
        'city': raw['city'],
        'category': raw['category'],
        'tags': (raw['tags'] as List?) ?? [],
        'photo': raw['photo'] ?? '',
        'description': raw['description'] ?? '',
        'location': {
          'lat':
              (raw['location']?['lat'] as num?)?.toDouble() ??
              (raw['lat'] as num?)?.toDouble(),
          'lng':
              (raw['location']?['lng'] as num?)?.toDouble() ??
              (raw['lng'] as num?)?.toDouble(),
        },
        'avg_rating': (raw['avg_rating'] as num?)?.toDouble(),
        'review_count': (raw['review_count'] as num?)?.toInt(),
        'est_cost': (raw['est_cost'] as num?)?.toInt(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('attractions').doc(id).set({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ok++;
    }
    return ok;
  }

  static String _slug(String s) {
    final lower = s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "-");
    final cleaned = lower.replaceAll(RegExp(r"(^-+|-+$)"), "");
    return cleaned.isEmpty ? 'place' : cleaned;
  }
}
