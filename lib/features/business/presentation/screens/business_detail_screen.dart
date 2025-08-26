// FILE: lib/features/business/presentation/screens/business_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ceylon/core/booking/widgets/verified_badge.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;
  final BusinessAnalyticsService _analyticsService =
      BusinessAnalyticsService.instance();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfBookmarked();

    // Track view analytics
    _analyticsService.trackBusinessView(widget.business.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkIfBookmarked() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(widget.business.id)
        .get();

    if (mounted) {
      setState(() {
        _isBookmarked = doc.exists;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to bookmark')),
      );
      return;
    }

    final bookmarkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(widget.business.id);

    if (_isBookmarked) {
      await bookmarkRef.delete();
      _analyticsService.trackBookmarkRemoved(widget.business.id);
    } else {
      await bookmarkRef.set({
        'businessId': widget.business.id,
        'name': widget.business.name,
        'category': widget.business.category,
        'photo': widget.business.photo,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _analyticsService.trackBookmarkAdded(widget.business.id);
    }

    if (mounted) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    }
  }

  void _shareBusiness() async {
    final String shareText =
        '${widget.business.name} - Check out this ${widget.business.category} on Ceylon!'
        '\n\nhttps://ceylon.app/business/${widget.business.id}';

    await SharePlus.instance.share(ShareParams(text: shareText));
    _analyticsService.trackBusinessShared(widget.business.id);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  void _callBusiness() async {
    if (widget.business.phone == null || widget.business.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final url = 'tel:${widget.business.phone}';
    await _launchURL(url);
    _analyticsService.trackBusinessCalled(widget.business.id);
  }

  void _getDirections() async {
    // In a real app, you would use the business address to generate directions
    final url =
        'https://maps.google.com/?q=${Uri.encodeComponent(widget.business.name)}';
    await _launchURL(url);
    _analyticsService.trackDirectionsRequested(widget.business.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareBusiness,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image with fallback
                    widget.business.photo != null
                        ? CachedNetworkImage(
                            imageUrl: widget.business.photo!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/placeholder_business.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/placeholder_business.jpg',
                            fit: BoxFit.cover,
                          ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha((0.7 * 255).round()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.business.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (widget.business.verified)
                        const VerifiedBadge(label: 'Verified', size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating row
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.business.ratingSafe(),
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.business.ratingSafe().toStringAsFixed(1)} (${widget.business.ratingCount})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category chips
                  Wrap(
                    spacing: 8.0,
                    children: [
                      Chip(
                        label: Text(widget.business.category),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact/Booking buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                        onPressed: _callBusiness,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        onPressed: _getDirections,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Events'),
                Tab(text: 'Reviews'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // About tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.business.description ??
                              'No description available.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  // Events tab
                  const Center(
                    child: Text('Upcoming events will be shown here.'),
                  ),

                  // Reviews tab
                  const Center(child: Text('Reviews will be shown here.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension on BusinessAnalyticsService to handle common tracking events
extension BusinessAnalyticsServiceExtension on BusinessAnalyticsService {
  // Helper for formatting date string
  String _formatDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Helper to get the daily stats path
  String _dailyStatsPath(String businessId) => 'analytics/$businessId/daily';

  Future<void> trackBusinessView(String businessId) async {
    try {
      // Increment views in the daily stats
      final date = DateTime.now();
      final dateString = _formatDateString(date);

      final statsRef = FirebaseFirestore.instance
          .collection(_dailyStatsPath(businessId))
          .doc(dateString);

      await statsRef.set({
        'views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking business view: $e');
    }
  }

  Future<void> trackBookmarkAdded(String businessId) async {
    try {
      // Increment bookmarks in the daily stats
      final date = DateTime.now();
      final dateString = _formatDateString(date);

      final statsRef = FirebaseFirestore.instance
          .collection(_dailyStatsPath(businessId))
          .doc(dateString);

      await statsRef.set({
        'bookmarks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking bookmark added: $e');
    }
  }

  Future<void> trackBookmarkRemoved(String businessId) async {
    try {
      // Decrement bookmarks in the daily stats
      final date = DateTime.now();
      final dateString = _formatDateString(date);

      final statsRef = FirebaseFirestore.instance
          .collection(_dailyStatsPath(businessId))
          .doc(dateString);

      await statsRef.set({
        'bookmarks': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking bookmark removed: $e');
    }
  }

  Future<void> trackBusinessShared(String businessId) async {
    // This could log to an 'actions' subcollection for more detailed analytics
    debugPrint('Business shared: $businessId');
  }

  Future<void> trackBusinessCalled(String businessId) async {
    debugPrint('Business called: $businessId');
  }

  Future<void> trackDirectionsRequested(String businessId) async {
    debugPrint('Directions requested: $businessId');
  }
}
