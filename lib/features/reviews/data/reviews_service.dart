import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all reviews for a place
  Stream<QuerySnapshot> getPlaceReviews(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get a user's reviews
  Stream<QuerySnapshot> getUserReviews() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_reviews')
        .orderBy('updated_at', descending: true)
        .snapshots();
  }

  // Add a review
  Future<void> addReview({
    required String placeId,
    required double rating,
    required String comment,
    String? placePhoto,
    String? placeCategory,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get user information
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous';

    // Create batch for atomic operations
    final batch = _firestore.batch();

    // Add to place reviews collection
    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc();

    batch.set(reviewRef, {
      'userId': userId,
      'name': userName,
      'rating': rating,
      'comment': comment.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Save to user's personal reviews
    final userReviewRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('my_reviews')
        .doc(placeId);

    batch.set(userReviewRef, {
      'place': placeId,
      'photo': placePhoto,
      'category': placeCategory,
      'rating': rating,
      'comment': comment.trim(),
      'reviewId': reviewRef.id, // Store reference to main review
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();

    // Update aggregate stats
    await updateRatingStats(placeId);
  }

  // Update a review
  Future<void> updateReview({
    required String placeId,
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create batch for atomic operations
    final batch = _firestore.batch();

    // Update place review
    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId);

    batch.update(reviewRef, {
      'rating': rating,
      'comment': comment.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update user's personal review
    final userReviewRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('my_reviews')
        .doc(placeId);

    batch.update(userReviewRef, {
      'rating': rating,
      'comment': comment.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();

    // Update aggregate stats
    await updateRatingStats(placeId);
  }

  // Delete a review
  Future<void> deleteReview({
    required String placeId,
    required String reviewId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create batch for atomic operations
    final batch = _firestore.batch();

    // Delete place review
    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId);

    batch.delete(reviewRef);

    // Delete user's personal review
    final userReviewRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('my_reviews')
        .doc(placeId);

    batch.delete(userReviewRef);

    // Commit the batch
    await batch.commit();

    // Update aggregate stats
    await updateRatingStats(placeId);
  }

  // Update rating statistics for a place
  Future<void> updateRatingStats(String placeId) async {
    try {
      // Get all reviews for this place
      final reviewsSnapshot = await _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .get();

      final reviews = reviewsSnapshot.docs;

      if (reviews.isEmpty) {
        // No reviews, reset ratings
        await _firestore.collection('places').doc(placeId).update({
          'avg_rating': 0.0,
          'review_count': 0,
        });
        return;
      }

      // Calculate average rating
      final ratings = reviews
          .map((doc) => (doc.data()['rating'] as num).toDouble())
          .toList();

      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      // Update place document
      await _firestore.collection('places').doc(placeId).update({
        'avg_rating': double.parse(avgRating.toStringAsFixed(2)),
        'review_count': ratings.length,
      });
    } catch (e) {
      debugPrint('Error updating rating stats: $e');
      rethrow;
    }
  }

  // Get the current user's review for a place
  Future<Map<String, dynamic>?> getUserReviewForPlace(String placeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return null;
    }

    try {
      // Check if user has reviewed this place
      final reviewsSnapshot = await _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return null;
      }

      final doc = reviewsSnapshot.docs.first;
      final data = doc.data();

      return {
        'reviewId': doc.id,
        'rating': (data['rating'] as num).toDouble(),
        'comment': data['comment'] as String,
        'timestamp': data['timestamp'] as Timestamp,
      };
    } catch (e) {
      debugPrint('Error getting user review: $e');
      return null;
    }
  }
}
