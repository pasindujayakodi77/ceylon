import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ceylon/core/booking/widgets/booking_buttons.dart';
import 'package:ceylon/features/events/presentation/widgets/published_events_carousel.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  DocumentSnapshot<Map<String, dynamic>>? _snap;
  bool _loading = true;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _load();
    // record a visit (analytics)
    BusinessAnalyticsService.instance.recordVisitor(widget.businessId);
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .get();

    _snap = doc;
    _loading = false;

    // check favorite
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final fav = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites_businesses')
          .doc(widget.businessId)
          .get();
      _isFav = fav.exists;
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save favorites')),
      );
      return;
    }

    setState(() => _isFav = !_isFav);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites_businesses')
        .doc(widget.businessId);

    if (_isFav) {
      await ref.set({'saved_at': FieldValue.serverTimestamp()});
      // optional daily metric
      await BusinessAnalyticsService.instance.recordFavoriteAdded(
        widget.businessId,
      );
    } else {
      await ref.delete();
      await BusinessAnalyticsService.instance.recordFavoriteRemoved(
        widget.businessId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_snap == null || !_snap!.exists) {
      return const Scaffold(body: Center(child: Text('Business not found')));
    }

    final data = _snap!.data()!;
    final name = (data['name'] ?? 'Business') as String;
    final photo = (data['photo'] ?? '') as String;
    final category = (data['category'] ?? 'other') as String;
    final desc = (data['description'] ?? '') as String;
    final phone = (data['phone'] ?? '') as String?;
    final formUrl = (data['bookingFormUrl'] ?? '') as String?;
    final avg = (data['avg_rating'] as num?)?.toDouble();
    final count = (data['review_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: _isFav ? 'Remove favorite' : 'Save favorite',
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Cover
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
                child: Center(child: Icon(Icons.store, size: 64)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + chips
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Chip(
                      label: Text(category),
                      backgroundColor: Colors.blue.shade50,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    if (avg != null)
                      Chip(
                        label: Text('⭐ ${avg.toStringAsFixed(1)} ($count)'),
                        backgroundColor: Colors.amber.shade50,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (desc.isNotEmpty) ...[
                  Text(desc),
                  const SizedBox(height: 16),
                ],

                // Booking buttons
                BookingButtons(
                  phone: (phone != null && phone.trim().isNotEmpty)
                      ? phone
                      : null,
                  bookingFormUrl: (formUrl != null && formUrl.trim().isNotEmpty)
                      ? formUrl
                      : null,
                  title: name,
                  contextNote: 'Inquiry from CEYLON app',
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Events for this business
                PublishedEventsCarousel(
                  businessId: widget.businessId,
                  title: '📅 Events & Promotions',
                  limit: 8,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
