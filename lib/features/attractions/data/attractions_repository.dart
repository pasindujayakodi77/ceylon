import 'package:cloud_firestore/cloud_firestore.dart';

class AttractionPin {
  final String id;
  final String name;
  final String? city;
  final String? category;
  final String? photo;
  final String? description;
  final double lat;
  final double lng;
  final double? avgRating;

  AttractionPin({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.city,
    this.category,
    this.photo,
    this.description,
    this.avgRating,
  });

  static AttractionPin fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final loc = (m['location'] ?? {}) as Map<String, dynamic>;
    final lat =
        (loc['lat'] as num?)?.toDouble() ?? (m['lat'] as num).toDouble();
    final lng =
        (loc['lng'] as num?)?.toDouble() ?? (m['lng'] as num).toDouble();
    return AttractionPin(
      id: d.id,
      name: (m['name'] ?? 'Place').toString(),
      city: (m['city'] ?? '').toString().isEmpty
          ? null
          : (m['city'] ?? '').toString(),
      category: (m['category'] ?? '').toString().isEmpty
          ? null
          : (m['category'] ?? '').toString(),
      photo: (m['photo'] ?? '').toString().isEmpty
          ? null
          : (m['photo'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      lat: lat,
      lng: lng,
      avgRating: (m['avg_rating'] as num?)?.toDouble(),
    );
  }
}

class AttractionsRepository {
  final _db = FirebaseFirestore.instance;

  /// Firestore can only do range on ONE field in a query.
  /// So: do a lat-range query, then filter lng on the client.
  ///
  /// [paddingDeg] expands the box slightly to avoid refetching on tiny pans.
  Future<List<AttractionPin>> fetchInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    double paddingDeg = 0.15,
    int limit = 800,
  }) async {
    final s = (south < north ? south : north) - paddingDeg;
    final n = (south < north ? north : south) + paddingDeg;
    final w = (west < east ? west : east) - paddingDeg;
    final e = (west < east ? east : west) + paddingDeg;

    // Lat band query + orderBy same field is allowed (uses single-field index).
    final snap = await _db
        .collection('attractions')
        .where('location.lat', isGreaterThanOrEqualTo: s)
        .where('location.lat', isLessThanOrEqualTo: n)
        .orderBy('location.lat')
        .limit(limit)
        .get();

    // Filter longitude client-side
    final out = <AttractionPin>[];
    for (final d in snap.docs) {
      final m = d.data();
      final lng =
          (m['location']?['lng'] as num?)?.toDouble() ??
          (m['lng'] as num?)?.toDouble() ??
          0.0;
      if (lng >= w && lng <= e) out.add(AttractionPin.fromDoc(d));
    }
    return out;
  }
}
