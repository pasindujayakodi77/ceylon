import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';

/// Minimal attraction model we read from Firestore.
class Attraction {
  final String id;
  final String name;
  final String? category; // e.g., beach, temple, hike, cafe
  final String? city; // optional
  final String? description; // short text
  final double? lat;
  final double? lng;
  final double? avgRating; // from your cached rating step
  final int? reviewCount;
  final int? estCost; // optional LKR estimate (per person)
  final List<dynamic>? tags; // [ "family", "history", "wildlife" ]

  Attraction({
    required this.id,
    required this.name,
    this.category,
    this.city,
    this.description,
    this.lat,
    this.lng,
    this.avgRating,
    this.reviewCount,
    this.estCost,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'city': city,
    'description': description,
    'lat': lat,
    'lng': lng,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'estCost': estCost,
    'tags': tags,
  };
}

class GeminiRecommender {
  GeminiRecommender._();
  static final instance = GeminiRecommender._();

  final _db = FirebaseFirestore.instance;

  /// Retrieves the Gemini API key from dart-define.
  /// Supports either GEMINI_API_KEY or API_KEY definitions.
  String? get _apiKey {
    const key1 = String.fromEnvironment('GEMINI_API_KEY');
    const key2 = String.fromEnvironment('API_KEY');
    if (key1.isNotEmpty) return key1;
    if (key2.isNotEmpty) return key2;
    return null;
  }

  /// Load a pool of attractions for the model to choose from.
  /// You can refine (by region, category) before passing to Gemini.
  Future<List<Attraction>> fetchAttractionsPool({
    String? region,
    List<String>? categories,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection('attractions');

    if (region != null && region.isNotEmpty) {
      q = q.where('region', isEqualTo: region);
    }
    if (categories != null && categories.isNotEmpty) {
      q = q.where(
        'category',
        whereIn: categories.take(10).toList(),
      ); // Firestore limit: 10
    }

    // Prefer well‑rated, popular
    q = q.orderBy('avg_rating', descending: true).limit(limit);

    final snap = await q.get();
    return snap.docs.map((d) {
      final m = d.data();
      return Attraction(
        id: d.id,
        name: (m['name'] ?? '').toString(),
        category: (m['category'] ?? '').toString().isEmpty
            ? null
            : (m['category'] ?? '').toString(),
        city: (m['city'] ?? '').toString().isEmpty
            ? null
            : (m['city'] ?? '').toString(),
        description: (m['description'] ?? '').toString().isEmpty
            ? null
            : (m['description'] ?? '').toString(),
        lat:
            (m['location']?['lat'] as num?)?.toDouble() ??
            (m['lat'] as num?)?.toDouble(),
        lng:
            (m['location']?['lng'] as num?)?.toDouble() ??
            (m['lng'] as num?)?.toDouble(),
        avgRating: (m['avg_rating'] as num?)?.toDouble(),
        reviewCount: (m['review_count'] as num?)?.toInt(),
        estCost: (m['est_cost'] as num?)?.toInt(),
        tags: (m['tags'] as List?) ?? const [],
      );
    }).toList();
  }

  /// Try to get user’s current location (optional).
  Future<Position?> getCurrentPosition() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  /// Main call: ask Gemini to rank and explain recommendations.
  /// Returns a list with: id, score, reason
  Future<List<Map<String, dynamic>>> recommend({
    required List<Attraction> pool,
    required String travelerType, // "solo", "family", "couple", "group"
    required List<String> interests, // ["beach","history","wildlife","food"]
    int budgetLkr = 0, // 0 = no budget filter
    int days = 3,
    double? userLat,
    double? userLng,
    String? languageCode, // e.g., "en", "de"
  }) async {
    // If no key → fallback
    if (_apiKey == null || _apiKey!.isEmpty) {
      return _fallbackRank(pool, interests, budgetLkr, userLat, userLng);
    }

    final model = GenerativeModel(
      apiKey: _apiKey!,
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.6,
        topP: 0.9,
        topK: 40,
        maxOutputTokens: 1200,
        responseMimeType: 'application/json',
      ),
      safetySettings: const [], // keep defaults
    );

    // Keep payload small for context window. Send a compact list.
    final compact = pool
        .map(
          (a) => {
            'id': a.id,
            'name': a.name,
            'cat': a.category,
            'city': a.city,
            'lat': a.lat,
            'lng': a.lng,
            'r': a.avgRating,
            'rc': a.reviewCount,
            'cost': a.estCost,
            'tags': a.tags,
          },
        )
        .toList();

    final sys = '''
You are a travel recommender for Sri Lanka and nearby countries.
Given a list of attractions, return top picks as JSON with fields:
- id (from input)
- score (0..100)
- reason (2-3 concise sentences, localized if languageCode provided)
Focus on: travelerType, interests, budgetLkr (approx), proximity to userLat/userLng if provided, and average rating.
Never output anything except valid JSON array.
''';

    final user = {
      'travelerType': travelerType,
      'interests': interests,
      'budgetLkr': budgetLkr,
      'days': days,
      'languageCode': languageCode ?? 'en',
      'userLat': userLat,
      'userLng': userLng,
      'pool': compact,
    };

    try {
      final resp = await model.generateContent([
        Content.system(sys),
        Content.text(jsonEncode(user)),
      ]);

      final text = resp.text ?? '[]';
      final parsed = jsonDecode(text);
      if (parsed is List) {
        // Ensure only items from pool; clamp fields
        final allowed = {for (final a in pool) a.id: true};
        final out = <Map<String, dynamic>>[];
        for (final it in parsed.take(50)) {
          if (it is! Map) continue;
          final id = (it['id'] ?? '').toString();
          if (!allowed.containsKey(id)) continue;
          final score = (it['score'] is num)
              ? (it['score'] as num).toDouble().clamp(0, 100)
              : 0.0;
          final reason = (it['reason'] ?? '').toString();
          out.add({'id': id, 'score': score, 'reason': reason});
        }
        if (out.isNotEmpty) return out;
      }
      // If response bad → fallback
      return _fallbackRank(pool, interests, budgetLkr, userLat, userLng);
    } catch (_) {
      return _fallbackRank(pool, interests, budgetLkr, userLat, userLng);
    }
  }

  /// Simple local scoring if API fails (interest match + rating + distance + budget).
  List<Map<String, dynamic>> _fallbackRank(
    List<Attraction> pool,
    List<String> interests,
    int budgetLkr,
    double? userLat,
    double? userLng,
  ) {
    double distKm(Attraction a) {
      if (userLat == null ||
          userLng == null ||
          a.lat == null ||
          a.lng == null) {
        return 9999;
      }
      final dx = (userLat - a.lat!).abs();
      final dy = (userLng - a.lng!).abs();
      // rough distance (not geodesic) — ok for fallback
      return sqrt(dx * dx + dy * dy) * 111.0;
    }

    int interestScore(Attraction a) {
      final t = (a.tags ?? []).map((e) => e.toString().toLowerCase()).toSet();
      final cat = a.category?.toLowerCase();
      int s = 0;
      for (final i in interests) {
        final ii = i.toLowerCase();
        if (t.contains(ii)) s += 10;
        if (cat == ii) s += 12;
      }
      return s.clamp(0, 40);
    }

    return pool.map((a) {
      final base = ((a.avgRating ?? 4.0) * 10).clamp(0, 50); // 0..50
      final isBudgetOk = (a.estCost == null || budgetLkr == 0)
          ? 1.0
          : (a.estCost! <= budgetLkr ? 1.0 : 0.6);
      final near = distKm(a);
      final nearScore = near > 200 ? 0.0 : (200 - near) * 0.15; // max ~30
      final score = base * isBudgetOk + interestScore(a) + nearScore;
      return {
        'id': a.id,
        'score': score.clamp(0, 100),
        'reason':
            'Matched your interests. ${a.city ?? ''} • Rating ${(a.avgRating ?? 4.0).toStringAsFixed(1)}',
      };
    }).toList()..sort(
      (a, b) => (b['score'] as num).compareTo(a['score'] as num),
    );
  }
}
