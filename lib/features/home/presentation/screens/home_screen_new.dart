import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_app_bar.dart';
import 'package:ceylon/features/home/presentation/widgets/feature_card.dart';
import 'package:ceylon/features/home/presentation/widgets/highlight_card.dart';
import 'package:ceylon/features/home/presentation/widgets/section_header.dart';
import 'package:ceylon/features/home/presentation/widgets/weather_widget.dart';
import 'package:ceylon/features/business/presentation/widgets/promoted_businesses_carousel.dart';
import 'package:ceylon/features/map/presentation/screens/attractions_map_screen_new.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen_v2.dart';
import 'package:ceylon/features/journal/presentation/screens/trip_journal_screen.dart';
import 'package:ceylon/features/itinerary/presentation/screens/itinerary_list_screen.dart';
import 'package:ceylon/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ceylon/features/currency/presentation/screens/currency_and_tips_screen.dart';
import 'package:ceylon/features/recommendations/presentation/screens/recommendations_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ceylon/dev/dev_tools_screen.dart';
import 'package:flutter/foundation.dart';

class TouristHomeScreen extends StatefulWidget {
  const TouristHomeScreen({super.key});

  @override
  State<TouristHomeScreen> createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // Show floating button when scrolled down
      final showButton = _scrollController.offset > 200;
      if (showButton != _showFloatingButton) {
        setState(() => _showFloatingButton = showButton);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Traveler';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CeylonAppBar(
        title: 'Ceylon',
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=Ceylon+User&background=random',
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreenV2()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Welcome section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CeylonTokens.spacing16,
                  CeylonTokens.spacing8,
                  CeylonTokens.spacing16,
                  CeylonTokens.spacing16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $firstName',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: CeylonTokens.spacing8),
                    Text(
                          'Discover the wonders of Sri Lanka',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),

            // Weather widget
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing16,
                  vertical: CeylonTokens.spacing8,
                ),
                child: WeatherWidget.placeholder(
                  context,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              ),
            ),

            // Featured destinations
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Featured Destinations',
                    subtitle: 'Popular attractions around the island',
                    actionLabel: 'View All',
                    onActionPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttractionsMapScreenNew(),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 300.ms),

                  // Horizontal scrolling highlights
                  SizedBox(
                    height: 180,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing16,
                        vertical: CeylonTokens.spacing8,
                      ),
                      scrollDirection: Axis.horizontal,
                      children: [
                        // These would typically come from a database
                        HighlightCard(
                              title: 'Sigiriya Rock',
                              subtitle: 'Cultural Triangle',
                              backgroundColor: Colors.orange.shade300,
                              imageUrl: 'https://files.catbox.moe/zgnplx.jpg',
                              hasBadge: true,
                              badgeText: 'UNESCO',
                              onTap: () {
                                // Navigate to Sigiriya details
                              },
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: 0.2, end: 0),

                        HighlightCard(
                              title: 'Ella Train Ride',
                              subtitle: 'Central Highlands',
                              backgroundColor: Colors.green.shade300,
                              imageUrl: 'https://files.catbox.moe/stnoku.jpg',
                              onTap: () {
                                // Navigate to Ella details
                              },
                            )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .slideX(begin: 0.2, end: 0),

                        HighlightCard(
                              title: 'Galle Fort',
                              subtitle: 'Southern Coast',
                              backgroundColor: Colors.blue.shade300,
                              imageUrl: 'https://files.catbox.moe/435u29.jpg',
                              hasBadge: true,
                              badgeText: 'UNESCO',
                              onTap: () {
                                // Navigate to Galle details
                              },
                            )
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideX(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Plan Your Trip',
                    subtitle: 'Essential tools for your journey',
                  ).animate().fadeIn(delay: 700.ms),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CeylonTokens.spacing16,
                      vertical: CeylonTokens.spacing8,
                    ),
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: CeylonTokens.spacing16,
                      crossAxisSpacing: CeylonTokens.spacing16,
                      childAspectRatio: 1.2,
                      children: [
                        FeatureCard(
                              title: 'My Itineraries',
                              subtitle: 'Plan and organize your trips',
                              icon: Icons.map_outlined,
                              isPrimary: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ItineraryListScreen(),
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .scale(
                              delay: 800.ms,
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                            ),

                        FeatureCard(
                              title: 'Favorites',
                              subtitle: 'Your saved places',
                              icon: Icons.favorite_border,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FavoritesScreen(),
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(delay: 900.ms)
                            .scale(
                              delay: 900.ms,
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                            ),

                        FeatureCard(
                              title: 'Trip Journal',
                              subtitle: 'Capture your memories',
                              icon: Icons.book_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TripJournalScreen(),
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(delay: 1000.ms)
                            .scale(
                              delay: 1000.ms,
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                            ),

                        FeatureCard(
                              title: 'Explore Map',
                              subtitle: 'Discover nearby attractions',
                              icon: Icons.travel_explore,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AttractionsMapScreenNew(),
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(delay: 1100.ms)
                            .scale(
                              delay: 1100.ms,
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Travel resources
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Travel Resources',
                    subtitle: 'Useful information for your stay',
                  ).animate().fadeIn(delay: 1200.ms),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CeylonTokens.spacing16,
                      vertical: CeylonTokens.spacing8,
                    ),
                    child: Column(
                      children: [
                        // First row
                        Row(
                          children: [
                            Expanded(
                              child: FeatureCard(
                                title: 'Currency & Tips',
                                subtitle: 'Exchange rates and tipping guide',
                                icon: Icons.currency_exchange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CurrencyAndTipsScreen(),
                                    ),
                                  );
                                },
                              ).animate().fadeIn(delay: 1300.ms),
                            ),
                            const SizedBox(width: CeylonTokens.spacing16),
                            Expanded(
                              child: FeatureCard(
                                title: 'Events & Holidays',
                                subtitle: 'Sri Lankan holidays and events',
                                icon: Icons.event_note,
                                onTap: () {
                                  Navigator.pushNamed(context, '/calendar');
                                },
                              ).animate().fadeIn(delay: 1400.ms),
                            ),
                          ],
                        ),

                        const SizedBox(height: CeylonTokens.spacing16),

                        // AI Picks - Special card
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecommendationsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                          child: Ink(
                            padding: const EdgeInsets.all(
                              CeylonTokens.spacing16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.primary.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                CeylonTokens.radiusMedium,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    CeylonTokens.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: CeylonTokens.spacing16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Recommendations',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                      Text(
                                        'Personalized suggestions just for you',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer
                                                  .withValues(alpha: 0.8),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 1500.ms).shimmer(delay: 1800.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Featured businesses (using the existing component)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Featured Businesses',
                    subtitle: 'Local services to enhance your experience',
                  ).animate().fadeIn(delay: 1600.ms),

                  const PromotedBusinessesCarousel(
                    limit: 6,
                  ).animate().fadeIn(delay: 1700.ms),
                ],
              ),
            ),

            // Debug section in development mode
            if (kDebugMode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(CeylonTokens.spacing16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Dev Tools'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DevToolsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      // Floating action button to scroll to top (appears when scrolled)
      floatingActionButton: AnimatedScale(
        scale: _showFloatingButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 2,
          onPressed: _scrollToTop,
          mini: true,
          child: const Icon(Icons.arrow_upward),
        ),
      ),
    );
  }
}
