// This is an extension file to patch ItineraryItem compatibility issues
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:ceylon/features/itinerary/data/itinerary_model.dart';
import 'package:flutter/material.dart';

// Extension on the ItineraryItem class for compatibility conversion
extension ItineraryItemCompatibility on ItineraryItem {
  // Convert the model item to an adapter item
  adapter.ItineraryItem toAdapterItem() {
    final DateTime itemTime = DateTime(
      2022,
      1,
      1, // Dummy date
      startTime.hour,
      startTime.minute,
    );

    return adapter.ItineraryItem(
      id: id ?? 'unknown',
      title: title,
      startTime: itemTime,
      durationMinutes: 60, // Default duration
      note: description,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Convert the adapter item to a model item
  static ItineraryItem fromAdapterItem(adapter.ItineraryItem adapterItem) {
    final TimeOfDay itemTimeOfDay = TimeOfDay(
      hour: adapterItem.startTime.hour,
      minute: adapterItem.startTime.minute,
    );

    return ItineraryItem(
      id: adapterItem.id,
      title: adapterItem.title,
      description: adapterItem.note,
      startTime: itemTimeOfDay,
      type: ItineraryItemType.activity,
      locationName: null,
      imageUrl: adapterItem.imageUrl,
      latitude: adapterItem.latitude,
      longitude: adapterItem.longitude,
    );
  }
}
