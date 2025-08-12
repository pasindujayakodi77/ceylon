import 'package:ceylon/features/map/presentation/screens/attractions_map_screen.dart';
import 'package:ceylon/features/business/presentation/widgets/promoted_businesses_carousel.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ceylon/features/journal/presentation/screens/trip_journal_screen.dart';

import 'package:ceylon/l10n/app_localizations.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';

import 'package:ceylon/features/itinerary/presentation/screens/itinerary_list_screen.dart';
import 'package:ceylon/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ceylon/features/currency/presentation/screens/currency_and_tips_screen.dart';

import 'package:ceylon/features/holidays/presentation/screens/holiday_calendar_screen.dart';
import 'package:ceylon/features/recommendations/presentation/screens/recommendations_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:ceylon/dev/dev_tools_screen.dart';

class TouristHomeScreen extends StatelessWidget {
  const TouristHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        children: [
          Text(
            AppLocalizations.of(context)!.homeScreenTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Profile IconButton
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          if (kDebugMode)
            TextButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('Dev Tools'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevToolsScreen()),
                );
              },
            ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Trip Journal'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripJournalScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            child: Text(AppLocalizations.of(context)!.viewFavorites),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.myTrips),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ItineraryListScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttractionsMapScreen()),
              );
            },
            child: Text(AppLocalizations.of(context)!.viewAttractionsMap),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.currency_exchange),
            label: const Text('Currency & Tipping'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CurrencyAndTipsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.event_available),
            label: const Text('Public Holiday Calendar'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HolidayCalendarScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Picks'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecommendationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Carousel Section
          const PromotedBusinessesCarousel(
            title: '✨ Featured Businesses',
            limit: 12,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }
}
