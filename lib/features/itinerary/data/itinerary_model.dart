import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Itinerary {
  final String? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final List<ItineraryDay> days;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Itinerary({
    this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.days,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  Itinerary copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    List<ItineraryDay>? days,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      days: days ?? this.days,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate,
      'days': days.map((day) => day.toJson()).toList(),
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: (json['start_date'] as Timestamp).toDate(),
      days: (json['days'] as List<dynamic>)
          .map((day) => ItineraryDay.fromJson(day))
          .toList(),
      userId: json['user_id'],
      createdAt: (json['created_at'] as Timestamp).toDate(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  factory Itinerary.empty(String userId) {
    final now = DateTime.now();
    return Itinerary(
      title: 'New Trip',
      startDate: now,
      days: [ItineraryDay(date: now, items: [])],
      userId: userId,
      createdAt: now,
    );
  }

  int get totalDays => days.length;

  DateTime get endDate {
    if (days.isEmpty) return startDate;
    return startDate.add(Duration(days: days.length - 1));
  }

  String get dateRangeText {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }
}

class ItineraryDay {
  final String? id;
  final DateTime date;
  final List<ItineraryItem> items;
  final String? note;

  ItineraryDay({this.id, required this.date, required this.items, this.note});

  ItineraryDay copyWith({
    String? id,
    DateTime? date,
    List<ItineraryItem>? items,
    String? note,
  }) {
    return ItineraryDay(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'items': items.map((item) => item.toJson()).toList(),
      'note': note,
    };
  }

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      id: json['id'],
      date: (json['date'] as Timestamp).toDate(),
      items: (json['items'] as List<dynamic>)
          .map((item) => ItineraryItem.fromJson(item))
          .toList(),
      note: json['note'],
    );
  }

  String get dayName {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ItineraryItem {
  final String? id;
  final String title;
  final String? description;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final ItineraryItemType type;
  final String? locationName;
  final String? attractionId;
  final double? cost;
  final String? imageUrl;

  ItineraryItem({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    required this.type,
    this.locationName,
    this.attractionId,
    this.cost,
    this.imageUrl,
  });

  ItineraryItem copyWith({
    String? id,
    String? title,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ItineraryItemType? type,
    String? locationName,
    String? attractionId,
    double? cost,
    String? imageUrl,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      locationName: locationName ?? this.locationName,
      attractionId: attractionId ?? this.attractionId,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': {'hour': startTime.hour, 'minute': startTime.minute},
      'end_time': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'type': type.name,
      'location_name': locationName,
      'attraction_id': attractionId,
      'cost': cost,
      'image_url': imageUrl,
    };
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: TimeOfDay(
        hour: json['start_time']['hour'],
        minute: json['start_time']['minute'],
      ),
      endTime: json['end_time'] != null
          ? TimeOfDay(
              hour: json['end_time']['hour'],
              minute: json['end_time']['minute'],
            )
          : null,
      type: ItineraryItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ItineraryItemType.activity,
      ),
      locationName: json['location_name'],
      attractionId: json['attraction_id'],
      cost: json['cost'],
      imageUrl: json['image_url'],
    );
  }

  String get formattedStartTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedEndTime {
    if (endTime == null) return '';
    final hour = endTime!.hour.toString().padLeft(2, '0');
    final minute = endTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedTimeRange {
    if (endTime == null) return formattedStartTime;
    return '$formattedStartTime - $formattedEndTime';
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
