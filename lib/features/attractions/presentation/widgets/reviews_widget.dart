import 'package:ceylon/design_system/tokens.dart';
import 'package:flutter/material.dart';

class Review {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class ReviewsWidget extends StatelessWidget {
  final List<Review> reviews;

  const ReviewsWidget({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (reviews.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all reviews
              },
              child: Text('View all (${reviews.length})'),
            ),
          ],
        ),
        const SizedBox(height: CeylonTokens.spacing8),
        ...reviews.take(3).map((review) => _buildReviewItem(context, review)),
      ],
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: CeylonTokens.spacing16),
      padding: const EdgeInsets.all(CeylonTokens.spacing12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(review.userPhotoUrl),
                backgroundColor: colorScheme.primaryContainer,
                child: review.userPhotoUrl.isEmpty
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: CeylonTokens.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatDate(review.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRatingStars(context, review.rating),
            ],
          ),
          const SizedBox(height: CeylonTokens.spacing8),
          // Review comment
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(BuildContext context, double rating) {
    final starList = <Widget>[];
    final fullStars = rating.floor();
    final halfStar = (rating - fullStars) >= 0.5;

    for (var i = 0; i < 5; i++) {
      if (i < fullStars) {
        starList.add(const Icon(Icons.star, size: 18, color: Colors.amber));
      } else if (i == fullStars && halfStar) {
        starList.add(
          const Icon(Icons.star_half, size: 18, color: Colors.amber),
        );
      } else {
        starList.add(
          Icon(
            Icons.star_border,
            size: 18,
            color: Colors.amber.withValues(alpha: 0.5),
          ),
        );
      }
    }

    return Row(children: starList);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
