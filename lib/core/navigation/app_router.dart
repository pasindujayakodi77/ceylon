import 'package:ceylon/features/itinerary/presentation/routes/itinerary_routes.dart';
import 'package:ceylon/features/map/presentation/routes/map_routes.dart';
import 'package:ceylon/features/settings/presentation/screens/settings_screen.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen_v2.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_home_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_analytics_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_detail_screen.dart';
import 'package:ceylon/features/business/data/business_models.dart';
// business events/reviews are navigated with arguments via MaterialPageRoute
import 'package:ceylon/features/calendar/presentation/screens/holidays_events_calendar_screen.dart';
import 'package:ceylon/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:ceylon/features/admin/presentation/screens/verification_inbox_screen.dart';
import 'package:ceylon/features/reviews/presentation/screens/my_reviews_screen.dart';
import 'package:ceylon/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ceylon/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ceylon/features/favorites/presentation/screens/bookmarks_screen.dart';
import 'package:ceylon/features/currency/presentation/screens/currency_and_tips_screen.dart';
import 'package:ceylon/features/recommendations/presentation/screens/recommendations_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // First check itinerary routes
    final itineraryRoute = ItineraryRoutes.onGenerateRoute(settings);
    if (itineraryRoute != null) {
      return itineraryRoute;
    }

    // Handle business detail routes with parameters
    if (settings.name?.startsWith('/business/detail/') == true) {
      // Extract businessId from URL path
      final businessId = settings.name!.substring('/business/detail/'.length);
      if (businessId.isNotEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(businessId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Business Not Found')),
                      body: const Center(
                        child: Text(
                          'The business you are looking for does not exist.',
                        ),
                      ),
                    );
                  }

                  final business = Business.fromDoc(snapshot.data!);
                  return BusinessDetailScreen(business: business);
                },
              ),
        );
      }
    }

    // Handle /business/detail route with arguments
    if (settings.name == '/business/detail') {
      final businessId = settings.arguments;
      if (businessId is String) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(businessId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Business Not Found')),
                      body: const Center(
                        child: Text(
                          'The business you are looking for does not exist.',
                        ),
                      ),
                    );
                  }

                  final business = Business.fromDoc(snapshot.data!);
                  return BusinessDetailScreen(business: business);
                },
              ),
        );
      }
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
    // Screens that require a businessId must be navigated to with arguments or
    // pushed via MaterialPageRoute. Default to the dashboard from static routes.
    '/business/events': (_) => const BusinessDashboardScreen(),
    '/business/reviews': (_) => const BusinessDashboardScreen(),

    // Reviews routes - these should be accessed with arguments via MaterialPageRoute
    // Commented out because ReviewsScreen requires parameters
    // '/reviews': (_) => const ReviewsScreen(),
    '/reviews/mine': (_) => const MyReviewsScreen(),

    // Notifications
    '/notifications': (_) => const NotificationsScreen(),

    // Favorites
    '/favorites': (_) => const FavoritesScreen(),
    '/bookmarks': (_) => const BookmarksScreen(),

    // Currency & Tips
    '/currency': (_) => const CurrencyAndTipsScreen(),

    // Recommendations
    '/recommendations': (_) => const RecommendationsScreen(),

    // Admin routes
    '/admin': (_) => const AdminOverviewScreen(),
    '/admin/verification-requests': (_) => const VerificationInboxScreen(),
  };
}
