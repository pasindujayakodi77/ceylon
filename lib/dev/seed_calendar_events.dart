// FILE: lib/dev/seed_calendar_events.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Debug-only seeder for creating demo calendar events
class CalendarEventSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create 2-3 demo events under the current user's business for this month
  static Future<void> seedDemoEvents() async {
    if (!kDebugMode) {
      throw Exception('seedDemoEvents should only be called in debug mode');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to seed events');
    }

    // Use user ID as business ID for demo purposes
    final businessId = user.uid;

    // Get current month boundaries
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Sample demo events for the current month
    final demoEvents = [
      {
        'businessId': businessId,
        'title': 'Traditional Sri Lankan Cooking Class',
        'description':
            'Learn to cook authentic Sri Lankan dishes with local spices and traditional techniques. Perfect for food enthusiasts!',
        'banner':
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
        'promoCode': 'COOK20',
        'discountPct': 20.0,
        'startsAt': Timestamp.fromDate(
          DateTime(now.year, now.month, 15, 10, 0),
        ),
        'endsAt': Timestamp.fromDate(DateTime(now.year, now.month, 15, 13, 0)),
        'tags': ['cooking', 'culture', 'food', 'traditional'],
        'city': 'Colombo',
        'published': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'businessId': businessId,
        'title': 'Sunset Whale Watching Tour',
        'description':
            'Experience the magical sunset while watching majestic whales in their natural habitat. Includes refreshments and professional guide.',
        'banner':
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
        'promoCode': 'WHALE15',
        'discountPct': 15.0,
        'startsAt': Timestamp.fromDate(
          DateTime(now.year, now.month, 22, 16, 0),
        ),
        'endsAt': Timestamp.fromDate(DateTime(now.year, now.month, 22, 19, 0)),
        'tags': ['wildlife', 'ocean', 'sunset', 'tour'],
        'city': 'Mirissa',
        'published': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'businessId': businessId,
        'title': 'Temple Heritage Walking Tour',
        'description':
            'Discover ancient Buddhist temples and learn about Sri Lankan spiritual heritage. Includes visit to 3 historic temples.',
        'banner':
            'https://images.unsplash.com/photo-1552832230-8b5ab9b56f3c?w=800',
        'promoCode': null,
        'discountPct': null,
        'startsAt': Timestamp.fromDate(DateTime(now.year, now.month, 28, 8, 0)),
        'endsAt': Timestamp.fromDate(DateTime(now.year, now.month, 28, 12, 0)),
        'tags': ['culture', 'heritage', 'temples', 'walking'],
        'city': 'Kandy',
        'published': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      // Add demo business metadata for the user
      await _firestore.collection('businesses').doc(businessId).set({
        'name': 'Demo Cultural Tours Ceylon',
        'description': 'Authentic Sri Lankan cultural experiences and tours',
        'phone': '+94771234567',
        'bookingFormUrl': 'https://forms.google.com/demo-booking-form',
        'city': 'Colombo',
        'isDemo': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add the demo events
      final batch = _firestore.batch();

      for (final eventData in demoEvents) {
        final eventRef = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('events')
            .doc(); // Auto-generate ID

        batch.set(eventRef, eventData);
      }

      await batch.commit();

      if (kDebugMode) {
        print(
          '✅ Seeded ${demoEvents.length} demo calendar events for business: $businessId',
        );
        print(
          '📅 Events scheduled between ${monthStart.toLocal().toString().split(' ')[0]} and ${monthEnd.toLocal().toString().split(' ')[0]}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to seed demo events: $e');
      }
      rethrow;
    }
  }

  /// Clear all demo events (for cleanup)
  static Future<void> clearDemoEvents() async {
    if (!kDebugMode) {
      throw Exception('clearDemoEvents should only be called in debug mode');
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final businessId = user.uid;

    try {
      // Query all events for this business
      final eventsSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('events')
          .get();

      // Delete in batch
      final batch = _firestore.batch();
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('🧹 Cleared ${eventsSnapshot.docs.length} demo events');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear demo events: $e');
      }
      rethrow;
    }
  }
}
