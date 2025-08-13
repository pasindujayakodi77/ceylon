import 'package:flutter/material.dart';
import 'package:ceylon/features/reviews/data/reviews_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsProvider extends ChangeNotifier {
  final ReviewsService _reviewsService = ReviewsService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add a review
  Future<void> addReview({
    required String placeId,
    required double rating,
    required String comment,
    String? placePhoto,
    String? placeCategory,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reviewsService.addReview(
        placeId: placeId,
        rating: rating,
        comment: comment,
        placePhoto: placePhoto,
        placeCategory: placeCategory,
      );
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onError(_error!);
    }
  }

  // Update a review
  Future<void> updateReview({
    required String placeId,
    required String reviewId,
    required double rating,
    required String comment,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reviewsService.updateReview(
        placeId: placeId,
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onError(_error!);
    }
  }

  // Delete a review
  Future<void> deleteReview({
    required String placeId,
    required String reviewId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reviewsService.deleteReview(placeId: placeId, reviewId: reviewId);
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onError(_error!);
    }
  }

  // Check if user has already reviewed
  Future<Map<String, dynamic>?> getUserReviewForPlace(String placeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _reviewsService.getUserReviewForPlace(placeId);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Stream for reviews
  Stream<QuerySnapshot> getPlaceReviews(String placeId) {
    return _reviewsService.getPlaceReviews(placeId);
  }

  // Stream for user reviews
  Stream<QuerySnapshot> getUserReviews() {
    return _reviewsService.getUserReviews();
  }
}
