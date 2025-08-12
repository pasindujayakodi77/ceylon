class Attraction {
  final String id;
  final String name;
  final String description;
  final String location;
  final String category;
  final List<String> images;
  final double latitude;
  final double longitude;
  final double rating;
  final List<String> tags;
  final bool isFavorite;

  // Added imageUrl getter to fix compatibility
  String? get imageUrl => images.isNotEmpty ? images[0] : null;

  Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.images,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.tags = const [],
    this.isFavorite = false,
  });

  Attraction copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? category,
    List<String>? images,
    double? latitude,
    double? longitude,
    double? rating,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Attraction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e as String).toList()
          : [],
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'category': category,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }
}
