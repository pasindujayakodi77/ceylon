// FILE: lib/features/itinerary/itinerary_routes.dart
import 'package:flutter/material.dart';

import '../screens/itinerary_list_screen.dart';
import '../screens/itinerary_builder_screen_new.dart';
import '../screens/itinerary_view_screen.dart';

class ItineraryRoutes {
  static const list = '/itineraries';
  static const builder = '/itinerary/edit';
  static const view = '/itinerary/view';

  // Delegate for app-level onGenerateRoute so callers can ask ItineraryRoutes
  // to handle dynamic route generation.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) =>
      buildItineraryRoute(settings);
}

class ItineraryBuilderArgs {
  final String? itineraryId; // null -> create new
  final String? initialName;
  final DateTime? startDate;
  final int? initialDays;

  const ItineraryBuilderArgs({
    this.itineraryId,
    this.initialName,
    this.startDate,
    this.initialDays,
  });
}

class ItineraryViewArgs {
  final String itineraryId;
  const ItineraryViewArgs(this.itineraryId);
}

Route<dynamic>? buildItineraryRoute(RouteSettings settings) {
  switch (settings.name) {
    case ItineraryRoutes.list:
      return MaterialPageRoute(builder: (_) => const ItineraryListScreen());
    case ItineraryRoutes.builder:
      final args = settings.arguments as ItineraryBuilderArgs?;
      return MaterialPageRoute(
        builder: (_) => ItineraryBuilderScreenNew(args: args),
      );
    case ItineraryRoutes.view:
      final args = settings.arguments as ItineraryViewArgs;
      return MaterialPageRoute(
        builder: (_) => ItineraryViewScreen(itineraryId: args.itineraryId),
      );
  }
  return null;
}
