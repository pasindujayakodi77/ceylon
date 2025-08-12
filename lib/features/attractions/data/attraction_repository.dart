import 'dart:convert';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:flutter/services.dart';

class AttractionRepository {
  /// Loads attractions from the local JSON file
  Future<List<Attraction>> getAttractions() async {
    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/json/attractions_mock.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert JSON to Attraction objects
      return jsonData.map((json) => Attraction.fromJson(json)).toList();
    } catch (e) {
      print('Error loading attractions: $e');
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

      // Filter by category
      final matchesCategory =
          category == null ||
          category.isEmpty ||
          attraction.category == category;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Toggles the favorite status of an attraction
  Attraction toggleFavorite(Attraction attraction) {
    return attraction.copyWith(isFavorite: !attraction.isFavorite);
  }
}
