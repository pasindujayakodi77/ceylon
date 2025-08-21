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
    _initializePlaceDocument();
    _checkUserReview();
  }

  Future<void> _checkUserReview() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final review = await _reviewsProvider.getUserReviewForPlace(
        widget.attractionName,
      );

      if (mounted) {
        setState(() {
          _userReview = review;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      body: SafeArea(
        child: Column(
          children: [
            // Rating summary card in a scrollable container
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: _buildRatingSummary(),
            ),

            const Divider(height: 16),

            // User's review form or existing review - wrapped in a container with fixed height
            Container(
              constraints: const BoxConstraints(
                maxHeight: 220,
              ), // Limit the height
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userReview != null
                  ? _buildUserExistingReview()
                  : SingleChildScrollView(
                      child: ReviewForm(
                        placeId: widget.attractionName,
                        placePhoto: widget.attractionPhoto,
                        placeCategory: widget.attractionCategory,
                        onSuccess: () {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Review submitted')),
                          );
                          _checkUserReview();
                        },
                        onError: (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Error: $error')),
                          );
                        },
                      ),
                    ),
            ),

            const Divider(height: 16),

            // Reviews header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "All Reviews",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list, size: 14),
                    label: const Text('Sort'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
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
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 60,
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If the place document doesn't exist yet, create it with default values
          // This fixes the "document not found" error for new places
          _initializePlaceDocument();
          return const SizedBox(
            height: 60,
            child: Center(child: Text('No ratings yet')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final avgRating = (data?['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (data?['review_count'] as num?)?.toInt() ?? 0;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (widget.attractionPhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.attractionPhoto!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 30),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Use minimum vertical space
                    children: [
                      Text(
                        widget.attractionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.attractionCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.attractionCategory!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: avgRating,
                            itemBuilder: (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemSize: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${avgRating.toStringAsFixed(1)} ($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                            style: const TextStyle(fontSize: 13),
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
      margin: const EdgeInsets.all(8),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum vertical space
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 14)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => _showEditReviewDialog(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RatingBarIndicator(
              rating: (_userReview!['rating'] as num).toDouble(),
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemSize: 18,
            ),
            const SizedBox(height: 4),
            // Use a scrollable container for long comments
            SingleChildScrollView(
              child: Text(
                _userReview!['comment'] as String,
                style: const TextStyle(fontSize: 14),
              ),
            ),
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: [
                    Image.asset(
                      'assets/images/empty_reviews.png',
                      height: 100, // Reduced height
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.rate_review_outlined,
                        size: 60, // Reduced size
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    const Text(
                      "No reviews yet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Be the first to review this place!",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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

  // Initialize place document with default values if it doesn't exist
  Future<void> _initializePlaceDocument() async {
    try {
      // Check if document exists first to avoid unnecessary writes
      final docRef = FirebaseFirestore.instance
          .collection('places')
          .doc(widget.attractionName);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create the document with default values
        await docRef.set({
          'name': widget.attractionName,
          'avg_rating': 0.0,
          'review_count': 0,
          'category': widget.attractionCategory,
          'photo': widget.attractionPhoto,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error initializing place document: $e');
    }
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
