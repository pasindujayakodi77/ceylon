import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ceylon/core/booking/widgets/booking_buttons.dart';
import 'package:flutter/material.dart';

/// Shows published events as a horizontal carousel with a list fallback.
/// - If [businessId] is provided: events for that business only.
/// - If null: shows upcoming published events across ALL businesses via collectionGroup.
class PublishedEventsCarousel extends StatelessWidget {
  final String? businessId;
  final String title;
  final int limit;
  final bool showAsListIfFew;

  const PublishedEventsCarousel({
    super.key,
    this.businessId,
    this.title = '🎟️ Upcoming Events',
    this.limit = 10,
    this.showAsListIfFew = true,
  });

  Query<Map<String, dynamic>> _buildQuery() {
    final now = Timestamp.fromDate(DateTime.now());
    if (businessId != null) {
      return FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('events')
          .where('published', isEqualTo: true)
          .where('endsAt', isGreaterThanOrEqualTo: now)
          .orderBy('endsAt')
          .limit(limit);
    }
    return FirebaseFirestore.instance
        .collectionGroup('events')
        .where('published', isEqualTo: true)
        .where('endsAt', isGreaterThanOrEqualTo: now)
        .orderBy('endsAt')
        .limit(limit);
  }

  @override
  Widget build(BuildContext context) {
    final q = _buildQuery();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snap.data!.docs;
        final cards = docs.map((d) {
          final data = d.data();
          return _EventCard(
            eventId: d.id,
            businessId: businessId ?? d.reference.parent.parent!.id,
            title: (data['title'] ?? 'Untitled').toString(),
            description: (data['description'] ?? '').toString(),
            banner: (data['banner'] ?? '').toString(),
            promoCode: (data['promoCode'] ?? '').toString(),
            discountPct: (data['discountPct'] is num)
                ? (data['discountPct'] as num).toInt()
                : null,
            startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
            endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
          );
        }).toList();

        if (showAsListIfFew && cards.length <= 2) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: title),
                const SizedBox(height: 8),
                ...cards.map(
                  (w) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: w,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: title),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String eventId;
  final String businessId;
  final String title;
  final String description;
  final String banner;
  final String promoCode;
  final int? discountPct;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const _EventCard({
    super.key,
    required this.eventId,
    required this.businessId,
    required this.title,
    required this.description,
    required this.banner,
    required this.promoCode,
    required this.discountPct,
    required this.startsAt,
    required this.endsAt,
  });

  String _dateRange() {
    final s = startsAt?.toLocal();
    final e = endsAt?.toLocal();
    if (s == null || e == null) return 'TBA';
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${fmt(s)} → ${fmt(e)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetails(context),
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (banner.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(banner, fit: BoxFit.cover),
              )
            else
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Color(0xFFEFEFEF),
                  child: Center(child: Icon(Icons.event, size: 48)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (discountPct != null)
                        Chip(
                          label: Text('-$discountPct%'),
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.greenAccent.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateRange(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (promoCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Promo: $promoCode',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                      ),
                    ),
                  ],
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

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _EventDetailsSheet(eventId: eventId, businessId: businessId),
    );
  }
}

/// Lightweight details sheet that reloads the latest event doc.
class _EventDetailsSheet extends StatelessWidget {
  final String eventId;
  final String businessId;

  const _EventDetailsSheet({required this.eventId, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('events')
        .doc(eventId);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: ref.get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data!.data() ?? {};
        final title = (data['title'] ?? 'Untitled').toString();
        final description = (data['description'] ?? '').toString();
        final banner = (data['banner'] ?? '').toString();
        final promoCode = (data['promoCode'] ?? '').toString();
        final discountPct = (data['discountPct'] is num)
            ? (data['discountPct'] as num).toInt()
            : null;
        final s = (data['startsAt'] as Timestamp?)?.toDate();
        final e = (data['endsAt'] as Timestamp?)?.toDate();

        String fmt(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        final dateText = (s != null && e != null)
            ? '${fmt(s)} → ${fmt(e)}'
            : 'TBA';

        // Fetch business fallback for phone and bookingFormUrl
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessId)
              .get(),
          builder: (context, bizSnap) {
            final bizDoc = bizSnap.data;
            final bizPhone = (bizDoc?.data()?['phone'] ?? '').toString();
            final bizForm = (bizDoc?.data()?['bookingFormUrl'] ?? '')
                .toString();

            final eventPhone = (data['phone'] ?? '').toString();
            final eventForm = (data['bookingFormUrl'] ?? '').toString();

            final effectivePhone = eventPhone.isNotEmpty
                ? eventPhone
                : (bizPhone.isNotEmpty ? bizPhone : null);
            final effectiveForm = eventForm.isNotEmpty
                ? eventForm
                : (bizForm.isNotEmpty ? bizForm : null);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 48,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (banner.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        banner,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    dateText,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (promoCode.isNotEmpty || discountPct != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (promoCode.isNotEmpty)
                          Chip(
                            label: Text('Promo: $promoCode'),
                            backgroundColor: Colors.purple.shade50,
                          ),
                        if (discountPct != null) const SizedBox(width: 8),
                        if (discountPct != null)
                          Chip(
                            label: Text('-$discountPct%'),
                            backgroundColor: Colors.greenAccent.shade100,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(description),
                  const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  BookingButtons(
                    phone: effectivePhone,
                    bookingFormUrl: effectiveForm,
                    title: title,
                    when: s,
                    contextNote: 'Event booking via CEYLON',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
