import 'package:ceylon/features/itinerary/presentation/routes/itinerary_routes.dart';
import 'package:ceylon/features/map/presentation/routes/map_routes.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // First check itinerary routes
    final itineraryRoute = ItineraryRoutes.onGenerateRoute(settings);
    if (itineraryRoute != null) {
      return itineraryRoute;
    }

    // Check other route patterns
    // For now, the MapRoutes are handled via the routes property in MaterialApp

    // Return null if no match found
    return null;
  }

  static final Map<String, WidgetBuilder> routes = {
    ...MapRoutes.routes,
    // Add other static routes here
  };
}
