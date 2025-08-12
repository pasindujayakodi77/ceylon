import 'package:ceylon/features/itinerary/presentation/screens/itinerary_builder_screen_new.dart';
import 'package:ceylon/features/itinerary/presentation/screens/itinerary_list_screen.dart';
import 'package:ceylon/features/itinerary/presentation/screens/itinerary_view_screen.dart';
import 'package:flutter/material.dart';

class ItineraryRoutes {
  static const String listItineraries = '/itineraries';
  static const String createItinerary = '/itineraries/create';
  static const String viewItinerary = '/itineraries/:id';
  static const String editItinerary = '/itineraries/:id/edit';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/itineraries') == true) {
      final uri = Uri.parse(settings.name!);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length == 1) {
        // /itineraries
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ItineraryListScreen(),
        );
      } else if (pathSegments.length == 2 && pathSegments[1] == 'create') {
        // /itineraries/create
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ItineraryBuilderScreen(),
        );
      } else if (pathSegments.length == 2) {
        // /itineraries/:id
        final id = pathSegments[1];
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ItineraryViewScreen(itineraryId: id),
        );
      } else if (pathSegments.length == 3 && pathSegments[2] == 'edit') {
        // /itineraries/:id/edit
        final id = pathSegments[1];
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ItineraryBuilderScreen(itineraryId: id),
        );
      }
    }
    return null;
  }
}
