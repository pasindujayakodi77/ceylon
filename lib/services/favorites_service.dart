import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user favorites
class FavoritesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cache of favorite attraction IDs for quicker lookup
  final Set<String> _favoritesCache = {};
  bool _initialized = false;

  /// Returns the current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;

  /// Returns true if the user is logged in
  bool get isLoggedIn => _userId != null;

  FavoritesService() {
    // Initialize cache when service is created
    _initializeCache();

    // Listen for auth state changes to update cache
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initializeCache();
      } else {
        _favoritesCache.clear();
        _initialized = false;
      }
    });
  }

  /// Initialize the favorites cache from Firestore
  Future<void> _initializeCache() async {
    if (_userId == null || _initialized) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();

      _favoritesCache.clear();
      for (var doc in snapshot.docs) {
        _favoritesCache.add(doc.id);
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing favorites cache: $e');
    }
  }

  /// Check if an attraction is favorited
  Future<bool> isFavorite(String attractionId) async {
    if (_userId == null) return false;

    // Wait for cache to initialize if needed
    if (!_initialized) {
      await _initializeCache();
    }

    return _favoritesCache.contains(attractionId);
  }

  /// Toggle favorite status for an attraction
  Future<bool> toggleFavorite(Attraction attraction) async {
    if (_userId == null) return false;

    final favoriteRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(attraction.id);

    try {
      if (_favoritesCache.contains(attraction.id)) {
        // Remove from favorites
        await favoriteRef.delete();
        _favoritesCache.remove(attraction.id);
      } else {
        // Add to favorites
        await favoriteRef.set({
          'name': attraction.name,
          'description': attraction.description,
          'location': attraction.location,
          'category': attraction.category,
          'images': attraction.images,
          'latitude': attraction.latitude,
          'longitude': attraction.longitude,
          'rating': attraction.rating,
          'tags': attraction.tags,
          'saved_at': FieldValue.serverTimestamp(),
        });
        _favoritesCache.add(attraction.id);
      }

      notifyListeners();
      return !_favoritesCache.contains(attraction.id);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return _favoritesCache.contains(attraction.id);
    }
  }

  /// Get all favorite attractions
  Future<List<Attraction>> getFavorites() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('saved_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Attraction(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Attraction',
          description: data['description'] as String? ?? '',
          location: data['location'] as String? ?? '',
          category: data['category'] as String? ?? 'other',
          images: List<String>.from(data['images'] ?? []),
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          tags: List<String>.from(data['tags'] ?? []),
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }
}
