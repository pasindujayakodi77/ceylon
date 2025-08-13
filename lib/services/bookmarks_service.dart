import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user bookmarks
class BookmarksService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cache of bookmarked itinerary IDs for quicker lookup
  final Set<String> _bookmarksCache = {};
  bool _initialized = false;

  /// Returns the current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;

  /// Returns true if the user is logged in
  bool get isLoggedIn => _userId != null;

  BookmarksService() {
    // Initialize cache when service is created
    _initializeCache();

    // Listen for auth state changes to update cache
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initializeCache();
      } else {
        _bookmarksCache.clear();
        _initialized = false;
      }
    });
  }

  /// Initialize the bookmarks cache from Firestore
  Future<void> _initializeCache() async {
    if (_userId == null || _initialized) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('itineraries')
          .get();

      _bookmarksCache.clear();
      for (var doc in snapshot.docs) {
        _bookmarksCache.add(doc.id);
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing bookmarks cache: $e');
    }
  }

  /// Check if an itinerary is bookmarked
  Future<bool> isBookmarked(String itineraryId) async {
    if (_userId == null) return false;

    // Wait for cache to initialize if needed
    if (!_initialized) {
      await _initializeCache();
    }

    return _bookmarksCache.contains(itineraryId);
  }

  /// Toggle bookmarked status for an itinerary
  Future<bool> toggleBookmark(
    String itineraryId,
    Map<String, dynamic> data,
  ) async {
    if (_userId == null) return false;

    final bookmarkRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('itineraries')
        .doc(itineraryId);

    try {
      if (_bookmarksCache.contains(itineraryId)) {
        // Remove from bookmarks
        await bookmarkRef.delete();
        _bookmarksCache.remove(itineraryId);
      } else {
        // Add to bookmarks
        await bookmarkRef.set({
          ...data,
          'bookmarked_at': FieldValue.serverTimestamp(),
        });
        _bookmarksCache.add(itineraryId);
      }

      notifyListeners();
      return !_bookmarksCache.contains(itineraryId);
    } catch (e) {
      print('Error toggling bookmark: $e');
      return _bookmarksCache.contains(itineraryId);
    }
  }

  /// Get all bookmarked itineraries
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('itineraries')
          .orderBy('bookmarked_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }
}
