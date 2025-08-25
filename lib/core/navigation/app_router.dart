import 'package:ceylon/features/itinerary/presentation/routes/itinerary_routes.dart';
import 'package:ceylon/features/map/presentation/routes/map_routes.dart';
import 'package:ceylon/features/settings/presentation/screens/settings_screen.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen_v2.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_home_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_analytics_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_events_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_reviews_screen.dart';
import 'package:ceylon/features/calendar/presentation/screens/holidays_events_calendar_screen.dart';
import 'package:ceylon/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:ceylon/features/admin/presentation/screens/verification_inbox_screen.dart';
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
    '/settings': (_) => const SettingsScreen(),
    '/profile': (_) => const ProfileScreenV2(),
    '/login': (_) => const LoginScreen(),
    '/calendar': (_) => const HolidaysEventsCalendarScreen(),

    // Business routes
    '/business': (_) => const BusinessHomeScreen(),
    '/business/dashboard': (_) => const BusinessDashboardScreen(),
    '/business/analytics': (_) => const BusinessAnalyticsScreen(),
    '/business/events': (_) => const BusinessEventsScreen(),
    '/business/reviews': (_) => const BusinessReviewsScreen(),
    // Admin routes
    '/admin': (_) => const AdminOverviewScreen(),
    '/admin/verification-requests': (_) => const VerificationInboxScreen(),
  };
}
