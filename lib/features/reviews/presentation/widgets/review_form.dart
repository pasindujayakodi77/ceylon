import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ceylon/features/reviews/providers/reviews_provider.dart';

class ReviewForm extends StatefulWidget {
  final String placeId;
  final String? placePhoto;
  final String? placeCategory;
  final Map<String, dynamic>? existingReview;
  final Function onSuccess;
  final Function(String) onError;

  const ReviewForm({
    super.key,
    required this.placeId,
    this.placePhoto,
    this.placeCategory,
    this.existingReview,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _commentController = TextEditingController();
  final _reviewsProvider = ReviewsProvider();
  double _rating = 4.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _commentController.text = widget.existingReview!['comment'] as String;
      _rating = widget.existingReview!['rating'] as double;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Your Review' : 'Leave a Review',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Your Rating'),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Write your experience',
                hintText: 'Share your thoughts about this place',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Review' : 'Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.existingReview != null) {
        // Update existing review
        await _reviewsProvider.updateReview(
          placeId: widget.placeId,
          reviewId: widget.existingReview!['reviewId'],
          rating: _rating,
          comment: _commentController.text.trim(),
          onSuccess: widget.onSuccess,
          onError: widget.onError,
        );
      } else {
        // Add new review
        await _reviewsProvider.addReview(
          placeId: widget.placeId,
          rating: _rating,
          comment: _commentController.text.trim(),
          placePhoto: widget.placePhoto,
          placeCategory: widget.placeCategory,
          onSuccess: widget.onSuccess,
          onError: widget.onError,
        );
      }
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
