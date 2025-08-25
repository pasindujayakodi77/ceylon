import 'package:ceylon/core/booking/widgets/verified_badge.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ceylon/features/business/presentation/screens/business_detail_screen.dart';

class PromotedBusinessesCarousel extends StatefulWidget {
  final String title;
  final int limit;

  /// If true, tapping a card will show a small inline preview sheet instead
  /// of navigating directly to the full business detail screen.
  final bool previewOnly;

  const PromotedBusinessesCarousel({
    super.key,
    this.title = '✨ Featured Businesses',
    this.limit = 12,
    this.previewOnly = false,
  });

  @override
  State<PromotedBusinessesCarousel> createState() =>
      _PromotedBusinessesCarouselState();

  // Deprecated single query kept for reference; using combined streams instead.
  // ignore: unused_element
  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('businesses')
        .where('promoted', isEqualTo: true)
        .where('promotedUntil', isNull: true)
        .orderBy('promotedWeight', descending: true);
  }

  // Because Firestore doesn't allow `where promotedUntil==null OR >= now` in one query,
  // we’ll fetch two streams and merge in UI: (1) no end date (null) and (2) future end date.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _streamCombined() {
    final base = FirebaseFirestore.instance.collection('businesses');
    final now = Timestamp.fromDate(DateTime.now());

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
}

class _PromotedBusinessesCarouselState
    extends State<PromotedBusinessesCarousel> {
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _streamCombinedWrapped() => widget._streamCombined();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _streamCombinedWrapped(),
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
            verified: (data['verified'] as bool?) ?? false,
            lastVerified: (data['verifiedAt'] as Timestamp?)?.toDate(),
            previewOnly: widget.previewOnly,
          );
        }).toList();

        return _PromotedCarouselView(title: widget.title, cards: cards);
      },
    );
  }
}

class _PromotedCarouselView extends StatefulWidget {
  final String title;
  final List<Widget> cards;
  const _PromotedCarouselView({required this.title, required this.cards});

  @override
  State<_PromotedCarouselView> createState() => _PromotedCarouselViewState();
}

class _PromotedCarouselViewState extends State<_PromotedCarouselView> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.86);
    _controller.addListener(() {
      final p = _controller.page ?? 0.0;
      setState(() => _page = p.round());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: cards.length,
              itemBuilder: (_, i) {
                // scale effect
                final current = (_controller.hasClients
                    ? (_controller.page ?? _controller.initialPage.toDouble())
                    : 0.0);
                final delta = (current - i).abs().clamp(0.0, 1.0);
                final scale = 1.0 - (delta * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 12 : 6,
                      right: i == cards.length - 1 ? 12 : 6,
                    ),
                    child: cards[i],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ),
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
  final bool verified;
  final DateTime? lastVerified;
  final bool previewOnly;

  const _BusinessCard({
    required this.businessId,
    required this.name,
    required this.photo,
    required this.category,
    required this.avgRating,
    required this.reviewCount,
    required this.description,
    required this.verified,
    this.lastVerified,
    this.previewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // Record an impression when the card is built (best-effort)
    BusinessAnalyticsService.instance.recordEvent(
      businessId,
      'promoted_impression',
    );

    return InkWell(
      onTap: () async {
        // Click tracking
        await BusinessAnalyticsService.instance.recordEvent(
          businessId,
          'promoted_click',
        );

        if (previewOnly) {
          // Show an inline preview sheet instead of navigating directly.
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => _BusinessPreviewSheet(
              businessId: businessId,
              name: name,
              photo: photo,
              category: category,
              avgRating: avgRating,
              reviewCount: reviewCount,
              description: description,
              verified: verified,
              lastVerified: lastVerified,
            ),
          );
          return;
        }

        // Navigate to the business detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(businessId: businessId),
          ),
        );
      },
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Builder(
                      builder: (context) {
                        // Precache image for smoother experience
                        final image = Image.network(photo, fit: BoxFit.cover);
                        precacheImage(image.image, context);
                        return image;
                      },
                    ),
                  )
                else
                  const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: Color(0xFFEFEFEF),
                      child: Center(child: Icon(Icons.store, size: 48)),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2), // Reduced from 4
                        // Put ratings and category on the same line with flexible layout
                        Row(
                          children: [
                            if (avgRating != null)
                              Text(
                                "⭐ ${avgRating!.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontSize: 10, // Reduced from 12
                                  color: Colors.amber,
                                ),
                              ),
                            if (avgRating != null)
                              const SizedBox(width: 4), // Reduced from 8
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2), // Reduced from 4
                        Expanded(
                          child: Text(
                            description,
                            maxLines: 1, // Reduced from 2
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1.1,
                              fontSize: 11,
                            ), // More compact
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (verified)
              Positioned(
                left: 8,
                top: 8,
                child: VerifiedBadge(
                  size: 16,
                  businessId: businessId,
                  lastVerified: lastVerified,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Inline preview shown when a promoted card is tapped. Small, contained UI
// with a prominent image, short description and a button to open full details.
class _BusinessPreviewSheet extends StatelessWidget {
  final String businessId;
  final String name;
  final String photo;
  final String category;
  final double? avgRating;
  final int reviewCount;
  final String description;
  final bool verified;
  final DateTime? lastVerified;

  const _BusinessPreviewSheet({
    required this.businessId,
    required this.name,
    required this.photo,
    required this.category,
    required this.avgRating,
    required this.reviewCount,
    required this.description,
    required this.verified,
    this.lastVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (verified)
                      VerifiedBadge(
                        businessId: businessId,
                        lastVerified: lastVerified,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (photo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: ColoredBox(
                      color: Color(0xFFEFEFEF),
                      child: Center(child: Icon(Icons.store, size: 48)),
                    ),
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    if (avgRating != null)
                      Text(
                        '⭐ ${avgRating!.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.amber),
                      ),
                    if (avgRating != null) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Close sheet then open full detail page.
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BusinessDetailScreen(businessId: businessId),
                            ),
                          );
                        },
                        child: const Text('View details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
