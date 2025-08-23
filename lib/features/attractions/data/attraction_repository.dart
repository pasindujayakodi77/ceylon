import 'dart:convert';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AttractionRepository {
  /// Loads attractions from the local JSON file
  Future<List<Attraction>> getAttractions() async {
    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/json/attractions_seed.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Get the items array from the root object
      final List<dynamic> items = jsonData['items'] ?? [];

      // Convert JSON to Attraction objects
      return items.map((json) => Attraction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading attractions: $e');
      return [];
    }
  }

  /// Filters attractions by search query and category
  Future<List<Attraction>> filterAttractions({
    required List<Attraction> attractions,
    String? searchQuery,
    String? category,
  }) async {
    return attractions.where((attraction) {
      // Filter by search query
      final matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          attraction.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          attraction.description.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          attraction.location.toLowerCase().contains(searchQuery.toLowerCase());

      // Filter by category - map UI categories to data categories
      bool matchesCategory = true;
      if (category != null && category.isNotEmpty && category != 'All') {
        final dataCategory = attraction.category.toLowerCase();
        switch (category.toLowerCase()) {
          case 'history':
            matchesCategory = dataCategory == 'history';
            break;
          case 'wildlife':
            matchesCategory = dataCategory == 'wildlife';
            break;
          case 'nature':
            matchesCategory =
                dataCategory == 'nature' || dataCategory == 'garden';
            break;
          case 'religious':
            matchesCategory = dataCategory == 'religious';
            break;
          case 'beach':
            matchesCategory =
                dataCategory == 'beach' || dataCategory == 'relax';
            break;
          case 'waterfall':
            matchesCategory = dataCategory == 'waterfall';
            break;
          case 'hiking':
            matchesCategory = dataCategory == 'hike' || dataCategory == 'view';
            break;
          case 'culture':
            matchesCategory =
                dataCategory == 'culture' || dataCategory == 'train';
            break;
          default:
            matchesCategory = true;
        }
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Toggles the favorite status of an attraction
  Future<Attraction> toggleFavorite(Attraction attraction) async {
    // Create updated attraction with toggled favorite status
    final updatedAttraction = attraction.copyWith(
      isFavorite: !attraction.isFavorite,
    );

    try {
      // In a real app, you'd save to a database or cloud service here.
      // For this demo, we'll simulate saving by adding a small delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Return the updated attraction
      return updatedAttraction;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Return the original attraction if there was an error
      return attraction;
    }
  }
}
