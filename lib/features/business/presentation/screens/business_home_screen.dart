// FILE: lib/features/business/presentation/screens/business_home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'package:ceylon/features/business/presentation/widgets/promoted_businesses_carousel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BusinessHomeScreen extends StatelessWidget {
  /// Optional user role override - if not provided, role is determined from profile
  final String? userRole;

  const BusinessHomeScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Not logged in - show tourist view by default
      return _buildTouristView(context, "tourist");
    }

    // If role is provided explicitly, use it
    if (userRole != null) {
      return _buildViewByRole(context, userRole!);
    }

    // Otherwise, fetch role from user profile
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // On error or no data, fallback to tourist view
          return _buildTouristView(context, "tourist");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'tourist';

        return _buildViewByRole(context, role);
      },
    );
  }

  /// Builds the appropriate view based on user role
  Widget _buildViewByRole(BuildContext context, String role) {
    if (role == 'business') {
      return _buildBusinessOwnerView(context);
    } else {
      return _buildTouristView(context, role);
    }
  }
  
  /// Builds the view for business owners with dashboard shortcuts
  Widget _buildBusinessOwnerView(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in to access your dashboard'))
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('businesses')
                  .where('ownerId', isEqualTo: currentUser.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final businesses = snapshot.data?.docs ?? [];
                
                if (businesses.isEmpty) {
                  return _buildEmptyBusinessOwnerView(context);
                }
                
                // User has at least one business
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildWelcomeCard(context),
                    const SizedBox(height: 16),
                    Text(
                      'Your Businesses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...businesses.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final business = Business.fromJson(data, id: doc.id);
                      return _buildBusinessCard(context, business);
                    }),
                    const SizedBox(height: 24),
                    _buildQuickActionsGrid(context),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to business dashboard where users can add a new business
          Navigator.of(context).pushNamed('/business/dashboard');
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Add Business'),
      ),
    );
  }
  
  /// Builds an empty state view for business owners with no businesses
  Widget _buildEmptyBusinessOwnerView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Welcome to Business Management',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t created any businesses yet. Start by adding your first business.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/business/dashboard');
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Add Your First Business'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds a welcome card for business owners
  Widget _buildWelcomeCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _getTimeBasedGreeting();
    final name = user?.displayName ?? 'Business Owner';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $name',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to your business dashboard',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds a card for each business
  Widget _buildBusinessCard(BuildContext context, dynamic business) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: business.photo != null
              ? NetworkImage(business.photo)
              : null,
          child: business.photo == null
              ? const Icon(Icons.business)
              : null,
        ),
        title: Text(business.name),
        subtitle: Text(business.category),
        trailing: business.verified
            ? const Icon(Icons.verified, color: Colors.blue)
            : null,
        onTap: () {
          Navigator.of(context).pushNamed(
            '/business/dashboard',
            arguments: business.id,
          );
        },
      ),
    );
  }
  
  /// Builds a grid of quick action buttons
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              onTap: () {
                Navigator.of(context).pushNamed('/business/analytics');
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.event,
              title: 'Manage Events',
              onTap: () {
                // Fallback to dashboard since events need businessId
                Navigator.of(context).pushNamed('/business/dashboard');
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.star,
              title: 'Reviews',
              onTap: () {
                // Fallback to dashboard since reviews need businessId
                Navigator.of(context).pushNamed('/business/dashboard');
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.trending_up,
              title: 'Promotions',
              onTap: () {
                // Fallback to dashboard since promotions need businessId
                Navigator.of(context).pushNamed('/business/dashboard');
              },
            ),
          ],
        ),
      ],
    );
  }
  
  /// Builds an individual action card for the quick actions grid
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds the tourist view with promoted businesses and nearby categories
  Widget _buildTouristView(BuildContext context, String role) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const PromotedBusinessesCarousel(title: 'Promoted businesses'),
          const SizedBox(height: 24),
          _buildBusinessCategories(context),
          const SizedBox(height: 24),
          _buildNearbyBusinessesSection(context),
        ],
      ),
    );
  }
  
  /// Builds a section displaying business categories
  Widget _buildBusinessCategories(BuildContext context) {
    final categories = [
      {'name': 'Restaurants', 'icon': Icons.restaurant},
      {'name': 'Hotels', 'icon': Icons.hotel},
      {'name': 'Activities', 'icon': Icons.kayaking},
      {'name': 'Shopping', 'icon': Icons.shopping_bag},
      {'name': 'Transport', 'icon': Icons.directions_car},
      {'name': 'Services', 'icon': Icons.miscellaneous_services},
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(
                context,
                name: category['name'] as String,
                icon: category['icon'] as IconData,
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Builds an individual category item
  Widget _buildCategoryItem(
    BuildContext context, {
    required String name,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to category screen
        // Could pass the category name as argument
        Navigator.of(context).pushNamed('/business');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Builds a section displaying nearby businesses based on location
  Widget _buildNearbyBusinessesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby Places',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('businesses')
                .limit(5)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              
              final businesses = snapshot.data?.docs ?? [];
              
              if (businesses.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No nearby places found'),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  final doc = businesses[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final business = Business.fromJson(data, id: doc.id);
                  return _buildNearbyBusinessItem(context, business);
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Builds an individual nearby business item
  Widget _buildNearbyBusinessItem(BuildContext context, dynamic business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/business/detail',
            arguments: business.id,
          );
        },
        child: Row(
          children: [
            // Business image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: business.photo != null
                    ? CachedNetworkImage(
                        imageUrl: business.photo,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.business),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.business),
                      ),
              ),
            ),
            // Business info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.category,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${business.ratingSafe().toStringAsFixed(1)} (${business.ratingCount})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (business.verified) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Verified',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Returns a greeting based on the current time
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
