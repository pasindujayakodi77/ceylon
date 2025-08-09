import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PromotedBusinessesCarousel extends StatelessWidget {
  final String title;
  final int limit;

  const PromotedBusinessesCarousel({
    super.key,
    this.title = '✨ Featured Businesses',
    this.limit = 12,
  });

  Query<Map<String, dynamic>> _query() {
    final now = Timestamp.fromDate(DateTime.now());
    // promoted == true AND (no end date OR ends in future)
    // Order by promotedWeight desc, then avg_rating desc as a tie-breaker
    return FirebaseFirestore.instance
        .collection('businesses')
        .where('promoted', isEqualTo: true)
        .where('promotedUntil', whereIn: [null])
        .orderBy('promotedWeight', descending: true)
    // Firestore can't combine where field==null with order unless indexed; so we do two queries fallback if needed.
    ;
  }

  // Because Firestore doesn't allow `where promotedUntil==null OR >= now` in one query,
  // we’ll fetch two streams and merge in UI: (1) no end date (null) and (2) future end date.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _streamCombined() {
    final now = Timestamp.fromDate(DateTime.now());
    final base = FirebaseFirestore.instance.collection('businesses');

    final qNoEnd = base
        .where('promoted', isEqualTo: true)
        .where('promotedUntil', isNull: true)
        .orderBy('promotedWeight', descending: true)
        .limit(limit);

    final qFutureEnd = base
        .where('promoted', isEqualTo: true)
        .where('promotedUntil', isGreaterThanOrEqualTo: now)
        .orderBy('promotedUntil')
        .limit(limit);

    final s1 = qNoEnd.snapshots().map((s) => s.docs);
    final s2 = qFutureEnd.snapshots().map((s) => s.docs);

    return StreamZip([s1, s2]).map((lists) {
      // Combine, dedupe by id, then sort by weight desc, rating desc
      final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final d in [...lists[0], ...lists[1]]) {
        map[d.id] = d;
      }
      final merged = map.values.toList();
      merged.sort((a, b) {
        final aw = (a.data()['promotedWeight'] as num?)?.toInt() ?? 0;
        final bw = (b.data()['promotedWeight'] as num?)?.toInt() ?? 0;
        if (bw != aw) return bw.compareTo(aw);
        final ar = (a.data()['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final br = (b.data()['avg_rating'] as num?)?.toDouble() ?? 0.0;
        return br.compareTo(ar);
      });
      return merged.take(limit).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _streamCombined(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snap.data!;
        final cards = docs.map((d) {
          final data = d.data();
          return _BusinessCard(
            businessId: d.id,
            name: (data['name'] ?? 'Business') as String,
            photo: (data['photo'] ?? '') as String,
            category: (data['category'] ?? 'other') as String,
            avgRating: (data['avg_rating'] as num?)?.toDouble(),
            reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
            description: (data['description'] ?? '') as String,
          );
        }).toList();

        return SizedBox(
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.86),
                  itemCount: cards.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 12 : 6,
                      right: i == cards.length - 1 ? 12 : 6,
                    ),
                    child: cards[i],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simple promoted business card
class _BusinessCard extends StatelessWidget {
  final String businessId;
  final String name;
  final String photo;
  final String category;
  final double? avgRating;
  final int reviewCount;
  final String description;

  const _BusinessCard({
    required this.businessId,
    required this.name,
    required this.photo,
    required this.category,
    required this.avgRating,
    required this.reviewCount,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to your BusinessDetailScreen
        // Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: businessId, name: name)));
      },
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (photo.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(photo, fit: BoxFit.cover),
              )
            else
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Color(0xFFEFEFEF),
                  child: Center(child: Icon(Icons.store, size: 48)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (avgRating != null)
                        Text(
                          "⭐ ${avgRating!.toStringAsFixed(1)} ($reviewCount)",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(category),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Minimal StreamZip (no external package)
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> _streams;
  StreamZip(this._streams);

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final values = List<T?>.filled(_streams.length, null, growable: false);
    final hasValue = List<bool>.filled(_streams.length, false, growable: false);
    var active = _streams.length;

    late StreamController<List<T>> ctl;
    final subs = <StreamSubscription<T>>[];

    void emitIfReady() {
      if (hasValue.every((v) => v)) {
        onData?.call(values.cast<T>());
      }
    }

    ctl = StreamController<List<T>>(
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );

    for (var i = 0; i < _streams.length; i++) {
      final idx = i;
      subs.add(
        _streams[i].listen(
          (v) {
            values[idx] = v;
            hasValue[idx] = true;
            emitIfReady();
          },
          onError: (e, st) {
            if (onError != null) onError(e, st);
          },
          onDone: () {
            active--;
            if (active == 0) onDone?.call();
          },
          cancelOnError: cancelOnError,
        ),
      );
    }

    return ctl.stream.listen(null);
  }
}
