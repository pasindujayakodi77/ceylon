import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/business/presentation/screens/business_analytics_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_events_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_reviews_screen.dart';
import 'package:ceylon/features/settings/presentation/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/features/business/presentation/widgets/promoted_businesses_carousel.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  String? _businessName;
  bool _isLoading = true;
  int _currentIndex = 0;
  // simple screen state

  final List<Widget> _screens = [
    const BusinessDashboardScreen(),
    const BusinessEventsScreen(),
    const BusinessAnalyticsScreen(),
    const BusinessReviewsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  // ...existing code...

  Future<void> _loadBusinessInfo() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          _businessName = doc.data()['name'] ?? 'My Business';
          _isLoading = false;
        });
      } else {
        setState(() {
          _businessName = 'No Business Found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading business info: $e');
      if (!mounted) return;
      setState(() {
        _businessName = 'Error Loading';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: CeylonTokens.seedColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        titleSpacing: CeylonTokens.spacing12,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _businessName?.isNotEmpty == true
                      ? _businessName![0].toUpperCase()
                      : 'B',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(width: CeylonTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _businessName ?? 'Business Dashboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Welcome back',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compact recommendation tile placed at the top
            if (_currentIndex == 0) ...[
              SizedBox(height: CeylonTokens.spacing16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing16,
                ),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => Padding(
                        padding: EdgeInsets.all(CeylonTokens.spacing16),
                        child: PromotedBusinessesCarousel(
                          title: 'Recommended for you',
                          limit: 12,
                          previewOnly: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: CeylonTokens.borderRadiusMedium,
                      boxShadow: CeylonTokens.shadowSmall,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing16,
                        vertical: CeylonTokens.spacing16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: CeylonTokens.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommended for you',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: CeylonTokens.spacing4),
                                Text(
                                  'Tap to explore trending businesses',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: CeylonTokens.spacing16),
            ],

            // Main content
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: CeylonTokens.shadowSmall,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(CeylonTokens.radiusMedium),
            topRight: Radius.circular(CeylonTokens.radiusMedium),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: CeylonTokens.spacing8,
              vertical: CeylonTokens.spacing8,
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(
                    Icons.dashboard,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.event_outlined),
                  selectedIcon: Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Events',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(
                    Icons.analytics,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.reviews_outlined),
                  selectedIcon: Icon(
                    Icons.reviews,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Reviews',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BusinessFeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;

  const BusinessFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = Colors.blue,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: CeylonTokens.spacing16,
        vertical: CeylonTokens.spacing8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: CeylonTokens.borderRadiusMedium,
        boxShadow: CeylonTokens.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: CeylonTokens.borderRadiusMedium,
        child: InkWell(
          onTap: onTap,
          borderRadius: CeylonTokens.borderRadiusMedium,
          child: Padding(
            padding: EdgeInsets.all(CeylonTokens.spacing16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(CeylonTokens.spacing12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: CeylonTokens.borderRadiusSmall,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                SizedBox(width: CeylonTokens.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: CeylonTokens.spacing4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
