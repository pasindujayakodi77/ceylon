import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String ownerUid;
  final bool verified;
  final bool promotedActive;
  final int promotedRank; // ordering among promoted
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.verified,
    required this.promotedActive,
    required this.promotedRank,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.photoUrl,
  });

  factory Business.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Business(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'],
      photoUrl: d['photoUrl'],
      ownerUid: d['ownerUid'] ?? '',
      verified: d['verified'] == true,
      promotedActive: d['promotedActive'] == true,
      promotedRank: (d['promotedRank'] ?? 0) as int,
      createdAt: (d['createdAt'] ?? Timestamp.now()) as Timestamp,
      updatedAt: (d['updatedAt'] ?? Timestamp.now()) as Timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'ownerUid': ownerUid,
        'verified': verified,
        'promotedActive': promotedActive,
        'promotedRank': promotedRank,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class Review {
  final String id;
  final String userId;
  final String businessId;
  final String text;
  final int rating; // 1..5
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Review(
      id: doc.id,
      userId: d['userId'] ?? '',
      businessId: d['businessId'] ?? '',
      text: d['text'] ?? '',
      rating: (d['rating'] ?? 0) as int,
      createdAt: (d['createdAt'] ?? Timestamp.now()) as Timestamp,
    );
  }
}

class BusinessEvent {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final Timestamp startAt;
  final Timestamp? endAt;
  final bool published;

  BusinessEvent({
    required this.id,
    required this.businessId,
    required this.title,
    required this.startAt,
    required this.published,
    this.description,
    this.endAt,
  });

  factory BusinessEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BusinessEvent(
      id: doc.id,
      businessId: d['businessId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'],
      startAt: (d['startAt'] ?? Timestamp.now()) as Timestamp,
      endAt: d['endAt'] as Timestamp?,
      published: d['published'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'title': title,
    'description': description,
    'startAt': startAt,
    'endAt': endAt,
    'published': published,
  };
}
