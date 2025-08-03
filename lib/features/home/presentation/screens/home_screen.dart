import 'package:ceylon/features/map/presentation/screens/attractions_map_screen.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ceylon/l10n/app_localizations.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';

import 'package:ceylon/features/itinerary/presentation/screens/itinerary_list_screen.dart';
import 'package:ceylon/features/favorites/presentation/screens/favorites_screen.dart';

class TouristHomeScreen extends StatelessWidget {
  const TouristHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.homeScreenTitle),
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
                  MaterialPageRoute(
                    builder: (_) => const ItineraryListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttractionsMapScreen(),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.viewAttractionsMap),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}
