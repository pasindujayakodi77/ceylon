import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'itinerary_adapter.dart';

class ItineraryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  ItineraryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _itinerariesCollection =>
      _firestore.collection('users').doc(_userId).collection('itineraries');

  Stream<List<Itinerary>> getItineraries() {
    return _itinerariesCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ItineraryAdapter.convertLegacyToItinerary(data, doc.id);
          }).toList();
        });
  }

  Future<Itinerary> getItinerary(String id) async {
    final doc = await _itinerariesCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Itinerary not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    return ItineraryAdapter.convertLegacyToItinerary(data, doc.id);
  }

  Future<Itinerary> getItineraryById(String id) async {
    return getItinerary(id);
  }

  Future<String> createItinerary(Itinerary itinerary) async {
    final docRef = await _itinerariesCollection.add(
      ItineraryAdapter.convertItineraryToLegacy(itinerary),
    );
    return docRef.id;
  }

  Future<void> updateItinerary(Itinerary itinerary) async {
    await _itinerariesCollection
        .doc(itinerary.id)
        .update(ItineraryAdapter.convertItineraryToLegacy(itinerary));
  }

  Future<void> deleteItinerary(String id) async {
    await _itinerariesCollection.doc(id).delete();
  }

  Future<String> addDayToItinerary(String itineraryId, ItineraryDay day) async {
    final itinerary = await getItinerary(itineraryId);
    final dayId = _uuid.v4();
    final newDay = day.copyWith(id: dayId);

    final days = [...itinerary.days, newDay];

    await _itinerariesCollection.doc(itineraryId).update({
      'days': days.map((day) => _prepareData(day.toJson())).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return dayId;
  }

  Future<void> updateDay(String itineraryId, ItineraryDay day) async {
    final itinerary = await getItinerary(itineraryId);
    final dayIndex = itinerary.days.indexWhere((d) => d.id == day.id);

    if (dayIndex == -1) throw Exception('Day not found');

    final days = [...itinerary.days];
    days[dayIndex] = day;

    await _itinerariesCollection.doc(itineraryId).update({
      'days': days.map((day) => _prepareData(day.toJson())).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> addItemToDay(
    String itineraryId,
    String dayId,
    ItineraryItem item,
  ) async {
    final itinerary = await getItinerary(itineraryId);
    final dayIndex = itinerary.days.indexWhere((day) => day.id == dayId);

    if (dayIndex == -1) throw Exception('Day not found');

    final itemId = _uuid.v4();
    final newItem = item.copyWith(id: itemId);

    final day = itinerary.days[dayIndex];
    final items = [...day.items, newItem];
    final updatedDay = day.copyWith(items: items);

    final days = [...itinerary.days];
    days[dayIndex] = updatedDay;

    await _itinerariesCollection.doc(itineraryId).update({
      'days': days.map((day) => _prepareData(day.toJson())).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return itemId;
  }

  Future<void> updateItem(
    String itineraryId,
    String dayId,
    ItineraryItem item,
  ) async {
    final itinerary = await getItinerary(itineraryId);
    final dayIndex = itinerary.days.indexWhere((day) => day.id == dayId);

    if (dayIndex == -1) throw Exception('Day not found');

    final day = itinerary.days[dayIndex];
    final itemIndex = day.items.indexWhere((i) => i.id == item.id);

    if (itemIndex == -1) throw Exception('Item not found');

    final items = [...day.items];
    items[itemIndex] = item;

    final updatedDay = day.copyWith(items: items);
    final days = [...itinerary.days];
    days[dayIndex] = updatedDay;

    await _itinerariesCollection.doc(itineraryId).update({
      'days': days.map((day) => _prepareData(day.toJson())).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(
    String itineraryId,
    String dayId,
    String itemId,
  ) async {
    final itinerary = await getItinerary(itineraryId);
    final dayIndex = itinerary.days.indexWhere((day) => day.id == dayId);

    if (dayIndex == -1) throw Exception('Day not found');

    final day = itinerary.days[dayIndex];
    final items = day.items.where((item) => item.id != itemId).toList();

    final updatedDay = day.copyWith(items: items);
    final days = [...itinerary.days];
    days[dayIndex] = updatedDay;

    await _itinerariesCollection.doc(itineraryId).update({
      'days': days.map((day) => _prepareData(day.toJson())).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _prepareData(
    Map<String, dynamic> data, {
    bool update = false,
  }) {
    // Remove id field for Firestore
    data.remove('id');

    // Convert TimeOfDay to Map
    if (data.containsKey('start_time') && data['start_time'] is TimeOfDay) {
      final startTime = data['start_time'] as TimeOfDay;
      data['start_time'] = {'hour': startTime.hour, 'minute': startTime.minute};
    }

    if (data.containsKey('end_time') && data['end_time'] is TimeOfDay) {
      final endTime = data['end_time'] as TimeOfDay;
      data['end_time'] = {'hour': endTime.hour, 'minute': endTime.minute};
    }

    // Convert timestamps
    if (!update && data.containsKey('created_at')) {
      data['created_at'] = FieldValue.serverTimestamp();
    }

    if (data.containsKey('updated_at')) {
      data['updated_at'] = FieldValue.serverTimestamp();
    }

    return data;
  }
}
