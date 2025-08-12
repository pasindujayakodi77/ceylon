import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// This is a compatibility adapter that helps with migrating from the old itinerary format to the new one
class ItineraryAdapter {
  static Future<List<Attraction>> getMockAttractions() async {
    // Sample attractions data as fallback when repository isn't available
    return [
      Attraction(
        id: '1',
        name: 'Sigiriya Rock Fortress',
        description:
            'Ancient rock fortress and palace ruins located in the Matale District.',
        location: 'Matale District, Central Province',
        category: 'UNESCO Heritage',
        images: ['https://picsum.photos/seed/mountain/800/500'],
        latitude: 7.9573,
        longitude: 80.7603,
        rating: 4.8,
        tags: ['heritage', 'history', 'hiking'],
      ),
      Attraction(
        id: '2',
        name: 'Galle Fort',
        description:
            'Historic fortified city built by the Portuguese and fortified by the Dutch.',
        location: 'Galle, Southern Province',
        category: 'Colonial Heritage',
        images: ['https://picsum.photos/seed/wildlife/800/500'],
        latitude: 6.0300,
        longitude: 80.2167,
        rating: 4.6,
        tags: ['colonial', 'architecture', 'seaside'],
      ),
      Attraction(
        id: '3',
        name: 'Yala National Park',
        description:
            'Famous wildlife reserve home to leopards, elephants and many bird species.',
        location: 'Yala, Southern Province',
        category: 'Nature & Wildlife',
        images: [
          'https://images.unsplash.com/photo-1590917259756-acc0a3046e83',
        ],
        latitude: 6.3352,
        longitude: 81.5316,
        rating: 4.7,
        tags: ['wildlife', 'safari', 'nature'],
      ),
      Attraction(
        id: '4',
        name: 'Temple of the Sacred Tooth Relic',
        description:
            'Buddhist temple that houses the relic of the tooth of the Buddha.',
        location: 'Kandy, Central Province',
        category: 'Religious Site',
        images: [
          'https://images.unsplash.com/photo-1586861256632-3f8e3a7ce952',
        ],
        latitude: 7.2944,
        longitude: 80.6412,
        rating: 4.5,
        tags: ['religion', 'buddhism', 'culture'],
      ),
      Attraction(
        id: '5',
        name: 'Nine Arches Bridge',
        description:
            'Famous railway bridge in Ella known for its beautiful architecture.',
        location: 'Ella, Uva Province',
        category: 'Landmark',
        images: [
          'https://images.unsplash.com/photo-1564507968718-0e6196e5c7a3',
        ],
        latitude: 6.8796,
        longitude: 81.0707,
        rating: 4.6,
        tags: ['railway', 'architecture', 'scenic'],
      ),
    ];
  }

  // Helper method to convert from the new model to a simplified version for storage compatibility
  static Map<String, dynamic> convertItineraryToLegacy(Itinerary itinerary) {
    // Extract just the day descriptions as simple strings for backward compatibility
    List<String> simpleDays = [];

    for (var day in itinerary.days) {
      String dayDescription = '${day.dayName} (${day.formattedDate}):';

      if (day.items.isEmpty) {
        dayDescription += ' No activities planned';
      } else {
        for (var item in day.items) {
          String timeStr =
              '${item.startTime.hour}:${item.startTime.minute.toString().padLeft(2, '0')}';
          dayDescription += '\n- $timeStr ${item.title}';
        }
      }

      simpleDays.add(dayDescription);
    }

    return {
      'title': itinerary.title,
      'description': itinerary.description ?? '',
      'days': simpleDays,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // Helper method to convert from legacy format to the new model
  static Itinerary convertLegacyToItinerary(
    Map<String, dynamic> data,
    String id,
  ) {
    final title = data['title'] as String? ?? 'Untitled Itinerary';
    final description = data['description'] as String?;
    final List<dynamic> legacyDays = data['days'] ?? [];
    final now = DateTime.now();

    // Create a list of itinerary days from the legacy format
    List<ItineraryDay> days = [];

    for (int i = 0; i < legacyDays.length; i++) {
      final date = now.add(Duration(days: i));
      final formatter = DateFormat('MMM d, yyyy');
      final dayName = i == 0 ? 'Day 1' : 'Day ${i + 1}';

      // Create a text-only item for each legacy day entry
      final item = ItineraryItem(
        id: 'legacy-$i',
        title: 'Legacy Activities',
        startTime: DateTime(2022, 1, 1, 9, 0),
        durationMinutes: 120,
        note: legacyDays[i].toString(),
      );

      days.add(
        ItineraryDay(
          id: 'legacy-day-$i',
          dayName: dayName,
          date: date,
          formattedDate: formatter.format(date),
          items: [item],
        ),
      );
    }

    return Itinerary(
      id: id,
      title: title,
      description: description,
      startDate: now,
      endDate: days.isEmpty ? now : now.add(Duration(days: days.length - 1)),
      days: days,
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      createdAt: data['created_at']?.toDate() ?? now,
      updatedAt: data['updated_at']?.toDate(),
      destination: 'Sri Lanka',
    );
  }
}

// Extended Itinerary model that includes additional fields
class Itinerary {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final List<ItineraryDay> days;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String destination;
  final String? coverImageUrl;

  Itinerary({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    required this.destination,
    this.coverImageUrl,
  });

  // Get formatted start date
  String get formattedStartDate => DateFormat('MMM d, yyyy').format(startDate);

  // Get formatted end date
  String get formattedEndDate => DateFormat('MMM d, yyyy').format(endDate);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'destination': destination,
      'cover_image_url': coverImageUrl,
    };
  }

  Itinerary copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<ItineraryDay>? days,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? destination,
    String? coverImageUrl,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      destination: destination ?? this.destination,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}

class ItineraryDay {
  final String id;
  final String dayName;
  final DateTime date;
  final String formattedDate;
  final List<ItineraryItem> items;
  final String? note;

  ItineraryDay({
    required this.id,
    required this.dayName,
    required this.date,
    required this.formattedDate,
    required this.items,
    this.note,
  });

  ItineraryDay copyWith({
    String? id,
    String? dayName,
    DateTime? date,
    String? formattedDate,
    List<ItineraryItem>? items,
    String? note,
  }) {
    return ItineraryDay(
      id: id ?? this.id,
      dayName: dayName ?? this.dayName,
      date: date ?? this.date,
      formattedDate: formattedDate ?? this.formattedDate,
      items: items ?? this.items,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_name': dayName,
      'date': date.toIso8601String(),
      'formatted_date': formattedDate,
      'items': items.map((item) => item.toJson()).toList(),
      'note': note,
    };
  }
}

class ItineraryItem {
  final String id;
  final String title;
  final DateTime startTime;
  final int durationMinutes;
  final String? note;
  final String? placeId;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? locationName;
  final double? cost;
  final ItineraryItemType type;
  final String? attractionId;

  ItineraryItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    this.note,
    this.placeId,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.description,
    this.locationName,
    this.cost,
    this.type = ItineraryItemType.activity,
    this.attractionId,
  });

  ItineraryItem copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    int? durationMinutes,
    String? note,
    String? placeId,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? description,
    String? locationName,
    double? cost,
    ItineraryItemType? type,
    String? attractionId,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      placeId: placeId ?? this.placeId,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      cost: cost ?? this.cost,
      type: type ?? this.type,
      attractionId: attractionId ?? this.attractionId,
    );
  }

  String get formattedStartTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? get endTime {
    if (durationMinutes <= 0) return null;
    final endDateTime = startTime.add(Duration(minutes: durationMinutes));
    return TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
  }

  String get formattedEndTime {
    if (endTime == null) return '';
    final hour = endTime!.hour.toString().padLeft(2, '0');
    final minute = endTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData get typeIcon {
    switch (type) {
      case ItineraryItemType.attraction:
        return Icons.place;
      case ItineraryItemType.activity:
        return Icons.directions_run;
      case ItineraryItemType.meal:
        return Icons.restaurant;
      case ItineraryItemType.accommodation:
        return Icons.hotel;
      case ItineraryItemType.transportation:
        return Icons.directions_car;
      default:
        return Icons.event;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': TimeOfDay(hour: startTime.hour, minute: startTime.minute),
      'duration_minutes': durationMinutes,
      'note': note,
      'place_id': placeId,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'location_name': locationName,
      'cost': cost,
      'type': type.name,
      'attraction_id': attractionId,
    };
  }
}

enum ItineraryItemType {
  attraction,
  activity,
  meal,
  accommodation,
  transportation,
  other,
}

extension ItineraryItemTypeExtension on ItineraryItemType {
  String get displayName {
    switch (this) {
      case ItineraryItemType.attraction:
        return 'Attraction';
      case ItineraryItemType.activity:
        return 'Activity';
      case ItineraryItemType.meal:
        return 'Meal';
      case ItineraryItemType.accommodation:
        return 'Accommodation';
      case ItineraryItemType.transportation:
        return 'Transportation';
      case ItineraryItemType.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ItineraryItemType.attraction:
        return Colors.blue;
      case ItineraryItemType.activity:
        return Colors.orange;
      case ItineraryItemType.meal:
        return Colors.red;
      case ItineraryItemType.accommodation:
        return Colors.purple;
      case ItineraryItemType.transportation:
        return Colors.green;
      case ItineraryItemType.other:
        return Colors.grey;
    }
  }
}
