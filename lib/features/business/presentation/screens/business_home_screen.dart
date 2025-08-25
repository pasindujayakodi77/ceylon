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
  // Simple filter state and personalization
  final Set<String> _selectedCategories = {};
  // (removed unused sort state)

  // Static category suggestions (can be dynamic later)
  final List<String> _categories = [
    'cafe',
    'hotel',
    'tour',
    'restaurant',
    'shop',
  ];

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_businessName ?? 'Business Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
            // Search + quick filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search your listings or categories',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) {
                      // simple local filter state - left as placeholder
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_currentIndex == 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final selected = _selectedCategories.contains(c);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                selected: selected,
                                label: Text(
                                  c[0].toUpperCase() + c.substring(1),
                                ),
                                onSelected: (s) => setState(() {
                                  if (s) {
                                    _selectedCategories.add(c);
                                  } else {
                                    _selectedCategories.remove(c);
                                  }
                                }),
                                avatar: const Icon(Icons.label, size: 16),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // (Promoted 'Recommended for you' carousel removed per request.)

            // Compact recommendation tile that opens a preview-only carousel.
            if (_currentIndex == 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: PromotedBusinessesCarousel(
                          title: 'Recommended for you',
                          limit: 12,
                          previewOnly: true,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.recommend, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Recommended for you — Tap to preview',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Main content
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews_outlined),
            activeIcon: Icon(Icons.reviews),
            label: 'Reviews',
          ),
        ],
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

  const BusinessFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(CeylonTokens.radiusSmall),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
