import 'dart:convert';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:flutter/services.dart';

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
  Attraction toggleFavorite(Attraction attraction) {
    return attraction.copyWith(isFavorite: !attraction.isFavorite);
  }
}
