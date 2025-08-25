// FILE: lib/features/business/data/business_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a business entity in the system.
///
/// Contains core business information, verification status, promotion details,
/// and rating information.
class Business {
  /// Unique identifier for the business.
  final String id;

  /// Name of the business.
  final String name;

  /// Optional detailed description of the business.
  final String? description;

  /// Category of the business (e.g., restaurant, hotel, activity).
  final String category;

  /// URL to the business's profile photo.
  final String? photo;

  /// Contact phone number for the business.
  final String? phone;

  /// User ID of the business owner.
  final String ownerId;

  /// Whether the business has been verified by platform administrators.
  final bool verified;

  /// Whether the business is currently promoted.
  final bool promoted;

  /// Priority weight for the business in promoted listings.
  final int promotedWeight;

  /// Timestamp when promotion ends.
  final Timestamp? promotedUntil;

  /// Average rating score (1-5 scale).
  final double ratingAvg;

  /// Total number of ratings received.
  final int ratingCount;

  /// Last update timestamp.
  final Timestamp updatedAt;

  /// Creates an immutable [Business] instance.
  const Business({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.category,
    this.description,
    this.photo,
    this.phone,
    this.verified = false,
    this.promoted = false,
    this.promotedWeight = 0,
    this.promotedUntil,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    required this.updatedAt,
  });

  /// Creates a [Business] from a Firestore document.
  factory Business.fromJson(Map<String, dynamic> json, {required String id}) {
    return Business(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      photo: json['photo'],
      phone: json['phone'],
      ownerId: json['ownerId'] ?? '',
      verified: json['verified'] ?? false,
      promoted: json['promoted'] ?? false,
      promotedWeight: json['promotedWeight'] ?? 0,
      promotedUntil: json['promotedUntil'],
      ratingAvg: (json['ratingAvg'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      updatedAt: json['updated_at'] ?? Timestamp.now(),
    );
  }

  /// Creates a [Business] from a Firestore document.
  factory Business.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Business.fromJson(data, id: doc.id);
  }

  /// Converts the [Business] instance to JSON for Firestore.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'photo': photo,
    'phone': phone,
    'ownerId': ownerId,
    'verified': verified,
    'promoted': promoted,
    'promotedWeight': promotedWeight,
    'promotedUntil': promotedUntil,
    'ratingAvg': ratingAvg,
    'ratingCount': ratingCount,
    'updated_at': updatedAt,
  };

  /// Checks if promotion is currently active based on the current time.
  bool isPromotedActive(DateTime now) {
    if (!promoted) return false;

    final until = promotedUntil?.toDate();
    if (until == null) return false;

    return now.isBefore(until);
  }

  /// Returns a safe rating value or 0 if no ratings.
  double ratingSafe() {
    if (ratingCount == 0) return 0.0;
    return ratingAvg;
  }

  /// Creates a copy of this [Business] with the given fields replaced.
  Business copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? photo,
    String? phone,
    String? ownerId,
    bool? verified,
    bool? promoted,
    int? promotedWeight,
    Timestamp? promotedUntil,
    double? ratingAvg,
    int? ratingCount,
    Timestamp? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      photo: photo ?? this.photo,
      phone: phone ?? this.phone,
      ownerId: ownerId ?? this.ownerId,
      verified: verified ?? this.verified,
      promoted: promoted ?? this.promoted,
      promotedWeight: promotedWeight ?? this.promotedWeight,
      promotedUntil: promotedUntil ?? this.promotedUntil,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents an event associated with a business.
///
/// Events are used for business promotions, special occasions, or
/// other time-based activities.
class BusinessEvent {
  /// Unique identifier for the event.
  final String id;

  /// ID of the business this event belongs to.
  final String businessId;

  /// Title of the event.
  final String title;

  /// Optional detailed description of the event.
  final String? description;

  /// Start date and time of the event.
  final Timestamp startAt;

  /// Optional end date and time of the event.
  final Timestamp? endAt;

  /// Whether the event is published and visible to users.
  final bool published;

  /// Optional URL to an image for the event.
  final String? imageUrl;

  /// Optional price for the event.
  final double? price;

  /// Optional maximum capacity for the event.
  final int? capacity;

  /// Creates an immutable [BusinessEvent] instance.
  const BusinessEvent({
    required this.id,
    required this.businessId,
    required this.title,
    required this.startAt,
    this.description,
    this.endAt,
    this.published = false,
    this.imageUrl,
    this.price,
    this.capacity,
  });

  /// Creates a [BusinessEvent] from a Firestore document.
  factory BusinessEvent.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return BusinessEvent(
      id: id,
      businessId: json['businessId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startAt: json['startAt'] ?? Timestamp.now(),
      endAt: json['endAt'],
      published: json['published'] ?? false,
      imageUrl: json['imageUrl'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      capacity: json['capacity'],
    );
  }

  /// Creates a [BusinessEvent] from a Firestore document.
  factory BusinessEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BusinessEvent.fromJson(data, id: doc.id);
  }

  /// Converts the [BusinessEvent] instance to JSON for Firestore.
  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'title': title,
    'description': description,
    'startAt': startAt,
    'endAt': endAt,
    'published': published,
    'imageUrl': imageUrl,
    'price': price,
    'capacity': capacity,
  };

  /// Checks if the event is in the future based on the current time.
  bool eventIsUpcoming(DateTime now) {
    final start = startAt.toDate();
    return start.isAfter(now);
  }

  /// Creates a copy of this [BusinessEvent] with the given fields replaced.
  BusinessEvent copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    Timestamp? startAt,
    Timestamp? endAt,
    bool? published,
    String? imageUrl,
    double? price,
    int? capacity,
  }) {
    return BusinessEvent(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      published: published ?? this.published,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
    );
  }
}

/// Represents a user review for a business.
///
/// Reviews include text feedback and a numerical rating.
class BusinessReview {
  /// Unique identifier for the review.
  final String id;

  /// ID of the user who left the review.
  final String userId;

  /// ID of the business being reviewed.
  final String businessId;

  /// Text content of the review.
  final String text;

  /// Numerical rating on a scale of 1-5.
  final int rating;

  /// When the review was created.
  final Timestamp createdAt;

  /// Creates an immutable [BusinessReview] instance.
  const BusinessReview({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  /// Creates a [BusinessReview] from a Firestore document.
  factory BusinessReview.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return BusinessReview(
      id: id,
      userId: json['userId'] ?? '',
      businessId: json['businessId'] ?? '',
      text: json['text'] ?? '',
      rating: json['rating'] ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Creates a [BusinessReview] from a Firestore document.
  factory BusinessReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BusinessReview.fromJson(data, id: doc.id);
  }

  /// Converts the [BusinessReview] instance to JSON for Firestore.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'businessId': businessId,
    'text': text,
    'rating': rating,
    'createdAt': createdAt,
  };

  /// Creates a copy of this [BusinessReview] with the given fields replaced.
  BusinessReview copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? text,
    int? rating,
    Timestamp? createdAt,
  }) {
    return BusinessReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      text: text ?? this.text,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents private feedback submitted to a business.
///
/// Unlike reviews, feedback is only visible to the business owner.
class BusinessFeedback {
  /// Unique identifier for the feedback.
  final String id;

  /// ID of the user who submitted the feedback.
  final String userId;

  /// ID of the business receiving the feedback.
  final String businessId;

  /// Text content of the feedback.
  final String text;

  /// Whether the business owner has read the feedback.
  final bool read;

  /// When the feedback was created.
  final Timestamp createdAt;

  /// Creates an immutable [BusinessFeedback] instance.
  const BusinessFeedback({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  /// Creates a [BusinessFeedback] from a Firestore document.
  factory BusinessFeedback.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return BusinessFeedback(
      id: id,
      userId: json['userId'] ?? '',
      businessId: json['businessId'] ?? '',
      text: json['text'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Creates a [BusinessFeedback] from a Firestore document.
  factory BusinessFeedback.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BusinessFeedback.fromJson(data, id: doc.id);
  }

  /// Converts the [BusinessFeedback] instance to JSON for Firestore.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'businessId': businessId,
    'text': text,
    'read': read,
    'createdAt': createdAt,
  };

  /// Creates a copy of this [BusinessFeedback] with the given fields replaced.
  BusinessFeedback copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? text,
    bool? read,
    Timestamp? createdAt,
  }) {
    return BusinessFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      text: text ?? this.text,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents daily analytics statistics for a business.
///
/// Used for tracking business performance over time.
class DailyStat {
  /// ID of the business these statistics belong to.
  final String businessId;

  /// Date for these statistics in YYYY-MM-DD format.
  final String date;

  /// Number of profile views.
  final int views;

  /// Number of times users bookmarked this business.
  final int bookmarks;

  /// Number of bookings or reservations made.
  final int bookings;

  /// When these statistics were last updated.
  final Timestamp updatedAt;

  /// Creates an immutable [DailyStat] instance.
  const DailyStat({
    required this.businessId,
    required this.date,
    this.views = 0,
    this.bookmarks = 0,
    this.bookings = 0,
    required this.updatedAt,
  });

  /// Creates a [DailyStat] from a Firestore document.
  factory DailyStat.fromJson(
    Map<String, dynamic> json, {
    required String date,
    required String businessId,
  }) {
    return DailyStat(
      businessId: businessId,
      date: date,
      views: json['views'] ?? 0,
      bookmarks: json['bookmarks'] ?? 0,
      bookings: json['bookings'] ?? 0,
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Creates a [DailyStat] from a Firestore document.
  factory DailyStat.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String businessId,
  }) {
    final data = doc.data() ?? {};
    return DailyStat.fromJson(data, date: doc.id, businessId: businessId);
  }

  /// Converts the [DailyStat] instance to JSON for Firestore.
  Map<String, dynamic> toJson() => {
    'views': views,
    'bookmarks': bookmarks,
    'bookings': bookings,
    'updatedAt': updatedAt,
  };

  /// Creates a copy of this [DailyStat] with the given fields replaced.
  DailyStat copyWith({
    String? businessId,
    String? date,
    int? views,
    int? bookmarks,
    int? bookings,
    Timestamp? updatedAt,
  }) {
    return DailyStat(
      businessId: businessId ?? this.businessId,
      date: date ?? this.date,
      views: views ?? this.views,
      bookmarks: bookmarks ?? this.bookmarks,
      bookings: bookings ?? this.bookings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
