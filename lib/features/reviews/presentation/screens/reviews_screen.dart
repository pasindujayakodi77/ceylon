import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ceylon/features/reviews/data/reviews_service.dart';
import 'package:ceylon/features/reviews/providers/reviews_provider.dart';
import 'package:ceylon/features/reviews/presentation/widgets/review_form.dart';
import 'package:ceylon/features/reviews/presentation/widgets/review_item.dart';

class ReviewsScreen extends StatefulWidget {
  final String attractionName;
  final String? attractionPhoto;
  final String? attractionCategory;

  const ReviewsScreen({
    super.key,
    required this.attractionName,
    this.attractionPhoto,
    this.attractionCategory,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _reviewsService = ReviewsService();
  final _reviewsProvider = ReviewsProvider();
  Map<String, dynamic>? _userReview;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserReview();
  }

  Future<void> _checkUserReview() async {
    setState(() => _isLoading = true);
    final review = await _reviewsProvider.getUserReviewForPlace(
      widget.attractionName,
    );
    setState(() {
      _userReview = review;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${widget.attractionName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _checkUserReview,
          ),
        ],
      ),
      body: Column(
        children: [
          // Rating summary card
          _buildRatingSummary(),

          const Divider(),

          // User's review form or existing review
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userReview != null
              ? _buildUserExistingReview()
              : ReviewForm(
                  placeId: widget.attractionName,
                  placePhoto: widget.attractionPhoto,
                  placeCategory: widget.attractionCategory,
                  onSuccess: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Review submitted')),
                    );
                    _checkUserReview();
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('❌ Error: $error')));
                  },
                ),

          const Divider(height: 32),

          // Reviews header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "All Reviews",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Sort'),
                  onPressed: () {
                    // Add sorting options later
                  },
                ),
              ],
            ),
          ),

          // Reviews list
          Expanded(child: _buildReviewsList()),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(widget.attractionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final avgRating = (data?['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (data?['review_count'] as num?)?.toInt() ?? 0;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (widget.attractionPhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.attractionPhoto!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attractionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (widget.attractionCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.attractionCategory!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: avgRating,
                            itemBuilder: (_, __) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemSize: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${avgRating.toStringAsFixed(1)} ($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserExistingReview() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _showEditReviewDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: (_userReview!['rating'] as num).toDouble(),
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemSize: 20,
            ),
            const SizedBox(height: 8),
            Text(_userReview!['comment'] as String),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reviewsService.getPlaceReviews(widget.attractionName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/empty_reviews.png',
                  height: 120,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No reviews yet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Be the first to review this place!",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final uid = FirebaseAuth.instance.currentUser?.uid;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMyReview = data['userId'] == uid;

            return ReviewItem(
              review: data,
              placeId: widget.attractionName,
              reviewId: doc.id,
              isCurrentUserReview: isMyReview,
              onRefresh: _checkUserReview,
            );
          },
        );
      },
    );
  }

  void _showEditReviewDialog() {
    if (_userReview == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Your Review',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ReviewForm(
              placeId: widget.attractionName,
              placePhoto: widget.attractionPhoto,
              placeCategory: widget.attractionCategory,
              existingReview: _userReview,
              onSuccess: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Review updated')),
                );
                _checkUserReview();
              },
              onError: (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('❌ Error: $error')));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
