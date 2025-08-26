// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:ceylon/features/business/data/business_models.dart';

class BusinessReviewsScreen extends StatefulWidget {
  final String businessId;
  const BusinessReviewsScreen({super.key, required this.businessId});

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  final _repo = BusinessRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  final _analytics = BusinessAnalyticsService(
    firestore: FirebaseFirestore.instance,
  );
  final _replyController = TextEditingController();

  bool _isBusinessOwner = false; // Will be set after checking ownership
  bool _showWithReplies = false;
  Map<int, int> _distributionData = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _loadDistribution();
    _checkIfOwner();
  }

  Future<void> _checkIfOwner() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .get();

      final ownerId = doc.data()?['ownerId'] as String?;
      if (mounted) {
        setState(() {
          _isBusinessOwner = ownerId != null && ownerId == userId;
        });
      }
    } catch (e) {
      debugPrint('Error checking business owner: $e');
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  /// Load the rating distribution data
  Future<void> _loadDistribution() async {
    try {
      final distribution = await _analytics.ratingDistribution(
        widget.businessId,
      );
      if (mounted) {
        setState(() {
          _distributionData = distribution;
        });
      }
    } catch (e) {
      // Handle error (could show a snackbar here)
      debugPrint('Error loading distribution: $e');
    }
  }

  /// Handle submitting a reply to a review
  void _handleReplySubmit(String reviewId, String replyText) async {
    if (replyText.trim().isEmpty) return;

    try {
      await _repo.replyToReview(widget.businessId, reviewId, replyText.trim());

      _replyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reply: ${e.toString()}')),
        );
      }
    }
  }

  /// Show dialog to reply to a review
  void _showReplyDialog(BuildContext context, BusinessReview review) {
    _replyController.text = review.ownerReply ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            review.ownerReply == null ? 'Reply to Review' : 'Edit Reply',
          ),
          content: TextField(
            controller: _replyController,
            decoration: const InputDecoration(
              hintText: 'Type your reply here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                _handleReplySubmit(review.id, _replyController.text);
                Navigator.pop(context);
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  /// Build a single review card
  Widget _buildReviewCard(BusinessReview review) {
    final formattedDate = DateFormat.yMMMd().format(review.createdAt.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  // Placeholder avatar with user's first initial
                  child: Text(
                    review.userId.isNotEmpty
                        ? review.userId[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${review.userId.substring(0, min(4, review.userId.length))}...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.text),

            // Owner reply section
            if (review.ownerReply != null) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Owner Reply',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (review.ownerReplyAt != null)
                          Text(
                            DateFormat.yMMMd().format(
                              review.ownerReplyAt!.toDate(),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review.ownerReply!),
                  ],
                ),
              ),
            ],

            // Reply button for business owners
            if (_isBusinessOwner)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showReplyDialog(context, review),
                  icon: Icon(
                    review.ownerReply == null ? Icons.reply : Icons.edit,
                  ),
                  label: Text(review.ownerReply == null ? 'Reply' : 'Edit'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the rating distribution section
  Widget _buildRatingDistribution() {
    // Calculate total number of ratings
    final totalRatings = _distributionData.values.fold<int>(
      0,
      (acc, val) => acc + val,
    );

    // Calculate average rating
    double averageRating = 0;
    if (totalRatings > 0) {
      double sum = 0;
      _distributionData.forEach((rating, cnt) {
        sum += rating * cnt;
      });
      averageRating = sum / totalRatings;
    }

    // Find the max count for scaling
    final maxCount = _distributionData.values.fold<int>(
      1,
      (curMax, val) => val > curMax ? val : curMax,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$totalRatings ${totalRatings == 1 ? 'review' : 'reviews'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating bars
            ...List.generate(5, (index) {
              final rating = 5 - index; // 5, 4, 3, 2, 1
              final count = _distributionData[rating] ?? 0;
              final percentage = totalRatings > 0 ? count / totalRatings : 0;
              final barWidth = maxCount > 0 ? count / maxCount : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      '$rating',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 8,
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: constraints.maxWidth * barWidth,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No reviews yet'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: StreamBuilder<List<BusinessReview>>(
        stream: _repo.streamReviews(widget.businessId, limit: 50),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? [];
          final currentReviews = _showWithReplies
              ? reviews
              : reviews.where((r) => r.ownerReply == null).toList();

          if (snapshot.connectionState == ConnectionState.waiting &&
              reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviews.isEmpty) {
            return _buildEmptyState();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRatingDistribution(),

                // Filter option
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showWithReplies ? 'All Reviews' : 'Awaiting Reply',
                        ),
                        Switch(
                          value: _showWithReplies,
                          onChanged: (value) =>
                              setState(() => _showWithReplies = value),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // List of reviews
                Expanded(
                  child: ListView.builder(
                    itemCount: currentReviews.length,
                    itemBuilder: (context, index) =>
                        _buildReviewCard(currentReviews[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
