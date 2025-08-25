// FILE: lib/features/business/presentation/widgets/promoted_businesses_carousel.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

/// A carousel widget that displays promoted businesses with auto-play and page indicators.
///
/// Features:
/// - Auto-scrolling PageView with smooth snap behavior
/// - Dots indicator for current position
/// - Weight-based ordering of businesses
/// - Expiration handling for promotions
/// - Loading skeleton placeholders
class PromotedBusinessesCarousel extends StatefulWidget {
  /// Title displayed above the carousel
  final String title;

  /// Maximum number of businesses to display
  final int pageSize;

  /// Auto-play interval in seconds (set to 0 to disable)
  final int autoPlayIntervalSeconds;

  const PromotedBusinessesCarousel({
    super.key,
    required this.title,
    this.pageSize = 10,
    this.autoPlayIntervalSeconds = 5,
  });

  @override
  State<PromotedBusinessesCarousel> createState() =>
      _PromotedBusinessesCarouselState();
}

class _PromotedBusinessesCarouselState
    extends State<PromotedBusinessesCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  bool _isPageChanging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9, // Show a bit of the next card
      initialPage: 0,
    );

    // Start auto-play if enabled
    if (widget.autoPlayIntervalSeconds > 0) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(
      Duration(seconds: widget.autoPlayIntervalSeconds),
      (_) {
        if (!_isPageChanging && mounted) {
          _advancePage();
        }
      },
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _advancePage() {
    final businessRepo = BusinessRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );

    businessRepo.listPromoted(limit: widget.pageSize).then((businesses) {
      if (businesses.isEmpty || !mounted) return;

      setState(() {
        _isPageChanging = true;
      });

      final nextPage = (_currentPage + 1) % businesses.length;
      _pageController
          .animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          )
          .then((_) {
            if (mounted) {
              setState(() {
                _currentPage = nextPage;
                _isPageChanging = false;
              });
            }
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = BusinessRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );

    // Create a query for promoted businesses
    final query = FirebaseFirestore.instance
        .collection('businesses')
        .where('promoted', isEqualTo: true)
        .where(
          'promotedUntil',
          isGreaterThan: Timestamp.now(),
        ) // Only active promotions
        .orderBy('promotedUntil')
        .orderBy('promotedWeight', descending: true) // Higher weights first
        .limit(widget.pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 280, // Taller to accommodate rating and book button
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading promotions: ${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Filter businesses that are still actively promoted
              final now = DateTime.now();
              final items = snapshot.data!.docs
                  .map((doc) => Business.fromDoc(doc))
                  .where((b) => b.isPromotedActive(now))
                  .toList();

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Main carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: items.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final business = items[index];
                        return _BusinessCard(
                          business: business,
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        );
                      },
                    ),
                  ),

                  // Dots indicator
                  if (items.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(items.length, (index) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a loading skeleton placeholder
  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: 3, // Show 3 loading placeholders
      itemBuilder: (context, _) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 150,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),

              // Title placeholder
              Container(
                height: 24,
                width: 180,
                margin: const EdgeInsets.only(left: 16, top: 16, right: 16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Subtitle placeholder
              Container(
                height: 16,
                width: 120,
                margin: const EdgeInsets.only(left: 16, top: 8, right: 16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Button placeholder
              Container(
                height: 36,
                width: 100,
                margin: const EdgeInsets.only(left: 16, top: 16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds an empty state when no promotions are found
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No promoted businesses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for special offers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying a promoted business in the carousel
class _BusinessCard extends StatelessWidget {
  final Business business;
  final EdgeInsetsGeometry? margin;

  const _BusinessCard({required this.business, this.margin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed('/business/detail', arguments: business.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business image
            SizedBox(
              height: 150,
              width: double.infinity,
              child: business.photo != null && business.photo!.isNotEmpty
                  ? Image.network(
                      business.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.business, size: 48),
                      ),
                    ),
            ),

            // Business information
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business name
                  Text(
                    business.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Category and rating row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category
                        Text(
                          business.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),

                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              business.ratingSafe().toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (business.ratingCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${business.ratingCount})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Book button
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      // Open WhatsApp if phone is available, otherwise navigate to detail
                      if (business.phone != null &&
                          business.phone!.isNotEmpty) {
                        final whatsappUrl =
                            'https://wa.me/${business.phone!.replaceAll(RegExp(r'[^\d+]'), '')}';
                        try {
                          await launchUrl(
                            Uri.parse(whatsappUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          // If WhatsApp fails, navigate to business detail
                          if (context.mounted) {
                            Navigator.of(context).pushNamed(
                              '/business/detail',
                              arguments: business.id,
                            );
                          }
                        }
                      } else {
                        Navigator.of(
                          context,
                        ).pushNamed('/business/detail', arguments: business.id);
                      }
                    },
                    icon: const Icon(Icons.book_online, size: 16),
                    label: const Text('Book'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Verified badge (if applicable)
                  if (business.verified)
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      avatar: const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.blue,
                      ),
                      label: const Text('Verified'),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
