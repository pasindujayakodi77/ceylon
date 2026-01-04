// FILE: lib/features/business/presentation/screens/business_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'package:ceylon/features/business/presentation/cubit/business_dashboard_cubit.dart';
import 'package:ceylon/features/business/presentation/widgets/request_verification_sheet.dart';
import 'business_analytics_screen.dart';
import 'business_events_screen.dart';
import 'business_reviews_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerId = currentUser?.uid;

    if (ownerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Dashboard')),
        body: const Center(
          child: Text('Please sign in to access your business dashboard'),
        ),
      );
    }

    return BlocProvider(
      create: (_) => BusinessDashboardCubit(
        repository: BusinessRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
      )..loadForOwner(ownerId),
      child: BlocConsumer<BusinessDashboardCubit, BusinessDashboardState>(
        listener: (context, state) {
          if (state is BusinessDashboardData && state.toast != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.toast!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Business Dashboard'),
              scrolledUnderElevation: 1,
            ),
            body: _buildBody(state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BusinessDashboardState state) {
    if (state is BusinessDashboardLoading) {
      return _buildLoadingSkeleton();
    } else if (state is BusinessDashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final ownerId = FirebaseAuth.instance.currentUser?.uid;
                if (ownerId != null) {
                  context.read<BusinessDashboardCubit>().loadForOwner(ownerId);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state is BusinessDashboardData) {
      return _DashboardContent(data: state);
    }

    // Fallback
    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ProfileCardSkeleton(),
        const SizedBox(height: 16),
        const _PromotionCardSkeleton(),
        const SizedBox(height: 16),
        const _VerificationCardSkeleton(),
        const SizedBox(height: 16),
        const _QuickLinksCardSkeleton(),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final BusinessDashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(business: data.business, isSaving: data.isSaving),
        const SizedBox(height: 16),
        _PromotionCard(
          business: data.business,
          promotedActive: data.promotedActive,
          isSaving: data.isSaving,
        ),
        const SizedBox(height: 16),
        if (!data.business.verified)
          _VerificationCard(businessId: data.business.id),
        const SizedBox(height: 16),
        _QuickLinksCard(
          business: data.business,
          pendingReviewsCount: data.pendingReviewsCount,
        ),
      ],
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final Business business;
  final bool isSaving;

  const _ProfileCard({required this.business, required this.isSaving});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late String _selectedCategory;

  final List<String> _categories = [
    'Restaurant',
    'Hotel',
    'Activity',
    'Shopping',
    'Transport',
    'Service',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(_ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if business data changes
    if (oldWidget.business.id != widget.business.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(
      text: widget.business.description ?? '',
    );
    _phoneController = TextEditingController(text: widget.business.phone ?? '');

    // Find category in the list or default to 'Other'
    _selectedCategory = _categories.contains(widget.business.category)
        ? widget.business.category
        : 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Business Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(),

              // Business Photo
              _buildPhotoSection(),
              const SizedBox(height: 16),

              // Form Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Business Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                initialValue: _selectedCategory,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
                items: _categories.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+94 XX XXX XXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Simple phone validation
                    if (!RegExp(r'^\+?[0-9\s]{10,15}$').hasMatch(value)) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 8),

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: widget.isSaving ? null : _saveBusiness,
                  child: widget.isSaving
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Saving...'),
                          ],
                        )
                      : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhoto =
        widget.business.photo != null && widget.business.photo!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          // Photo display
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 120,
              height: 120,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.business.photo!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 40),
                    )
                  : Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.add_a_photo_outlined, size: 40),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Photo upload functionality would go here
              // This is just a placeholder for the UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo upload not implemented in this demo'),
                ),
              );
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
          ),
        ],
      ),
    );
  }

  void _saveBusiness() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Create updated business object
    final updatedBusiness = widget.business.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      phone: _phoneController.text.trim(),
      // Photo would be updated in a real implementation
    );

    // Save the business via cubit
    context.read<BusinessDashboardCubit>().saveBusiness(updatedBusiness);
  }
}

class _PromotionCard extends StatefulWidget {
  final Business business;
  final bool promotedActive;
  final bool isSaving;

  const _PromotionCard({
    required this.business,
    required this.promotedActive,
    required this.isSaving,
  });

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  bool _isPromoted = false;
  double _weight = 0;
  DateTime? _untilDate;
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _updateFromBusiness();
  }

  @override
  void didUpdateWidget(_PromotionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id ||
        oldWidget.business.promoted != widget.business.promoted ||
        oldWidget.business.promotedWeight != widget.business.promotedWeight ||
        oldWidget.business.promotedUntil != widget.business.promotedUntil) {
      _updateFromBusiness();
    }
  }

  void _updateFromBusiness() {
    _isPromoted = widget.business.promoted;
    _weight = widget.business.promotedWeight.toDouble();
    _untilDate = widget.business.promotedUntil?.toDate();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.trending_up, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Promotion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.promotedActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),

            // Switch to enable/disable promotion
            SwitchListTile(
              title: const Text('Enable Promotion'),
              subtitle: Text(
                _isPromoted
                    ? 'Your business will appear at the top of search results'
                    : 'Activate to make your business more visible',
              ),
              value: _isPromoted,
              onChanged: (bool value) {
                setState(() {
                  _isPromoted = value;
                  if (value && _untilDate == null) {
                    // Default to 30 days from now if turning on
                    _untilDate = DateTime.now().add(const Duration(days: 30));
                  }
                });
              },
              secondary: Icon(
                _isPromoted ? Icons.star : Icons.star_border,
                color: _isPromoted ? colorScheme.primary : null,
              ),
            ),

            // Only show these options if promotion is enabled
            if (_isPromoted) ...[
              const SizedBox(height: 16),

              // Priority Slider
              Text(
                'Priority Weight',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('Higher weight shows higher in search results'),
              Slider(
                value: _weight,
                min: 0,
                max: 100,
                divisions: 10,
                label: _weight.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _weight = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // End date picker
              Text(
                'Promotion End Date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _untilDate != null
                      ? _dateFormat.format(_untilDate!)
                      : 'Select end date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _untilDate ?? now.add(const Duration(days: 30)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );

                  if (date != null) {
                    setState(() {
                      _untilDate = date;
                    });
                  }
                },
              ),
            ],

            const Divider(),

            // Save Button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: widget.isSaving ? null : _savePromotion,
                child: widget.isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Update Promotion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePromotion() {
    context.read<BusinessDashboardCubit>().togglePromotion(
      promoted: _isPromoted,
      weight: _weight.round(),
      until: _untilDate,
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String businessId;

  const _VerificationCard({required this.businessId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BusinessDashboardCubit>().state;

    // Get verification status
    String verificationStatus = 'none';
    bool isVerified = false;

    if (state is BusinessDashboardData) {
      verificationStatus = state.verificationStatus;
      isVerified = state.business.verified;
    }

    // Check the current status to determine what UI to show
    if (isVerified) {
      return _buildVerifiedCard(context);
    } else if (verificationStatus == 'pending') {
      return _buildPendingCard(context);
    } else {
      return _buildRequestCard(context);
    }
  }

  /// Build the card for when the business is already verified
  Widget _buildVerifiedCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Verified Business',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // Content
            Text(
              'Congratulations! Your business is verified. Customers can now see your verified badge.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),

            // Benefits
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow('Increased trust with customers'),
                  _buildBenefitRow('Higher ranking in search results'),
                  _buildBenefitRow('Access to premium features'),
                  _buildBenefitRow('Verified badge displayed on your profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the card for when verification is pending
  Widget _buildPendingCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Verification Pending',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // Content
            Text(
              'Your verification request is being reviewed by our team. '
              'This process typically takes 1-3 business days.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),

            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review in progress',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.orange.shade800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'ll notify you once your verification is complete',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the card for when no verification has been requested
  Widget _buildRequestCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.verified_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Verification',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // Content
            const Text(
              'Get your business verified to build trust with customers. '
              'Verified businesses display a badge and appear higher in search results.',
            ),
            const SizedBox(height: 16),

            // Requirements
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementRow('Business registration document'),
                  _buildRequirementRow('Owner identification proof'),
                  _buildRequirementRow('Business address proof'),
                  _buildRequirementRow('Contact details verification'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                icon: const Icon(Icons.verified),
                label: const Text('Request Verification'),
                onPressed: () => _requestVerification(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _requestVerification(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RequestVerificationSheet(businessId: businessId),
    );

    if (result == true && context.mounted) {
      // The cubit will handle showing the toast
    }
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  final Business business;
  final int pendingReviewsCount;

  const _QuickLinksCard({required this.business, this.pendingReviewsCount = 0});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // Grid of quick links
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildQuickLinkItem(
                  context,
                  icon: Icons.event,
                  title: 'Events',
                  subtitle: 'Manage your events',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BusinessEventsScreen(businessId: business.id),
                      ),
                    );
                  },
                ),
                _buildQuickLinkItem(
                  context,
                  icon: Icons.star,
                  title: 'Reviews',
                  subtitle: '$pendingReviewsCount pending',
                  showBadge: pendingReviewsCount > 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BusinessReviewsScreen(businessId: business.id),
                      ),
                    );
                  },
                ),
                _buildQuickLinkItem(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'View performance',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickLinkItem(
                  context,
                  icon: Icons.public,
                  title: 'View Listing',
                  subtitle: 'See customer view',
                  onTap: () {
                    // Navigate to public business detail page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View listing feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinkItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool showBadge = false,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(
            (0.4 * 255).round(),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pendingReviewsCount > 9
                        ? '9+'
                        : pendingReviewsCount.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Skeleton loaders for better UX during loading
class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(context, width: 180, height: 24),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 48),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 48),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 48),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 80),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _skeletonLine(context, width: 120, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionCardSkeleton extends StatelessWidget {
  const _PromotionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(context, width: 120, height: 24),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 56),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 24),
            const SizedBox(height: 8),
            _skeletonLine(context),
            const SizedBox(height: 16),
            _skeletonLine(context, height: 24),
            const SizedBox(height: 8),
            _skeletonLine(context, height: 48),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _skeletonLine(context, width: 150, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCardSkeleton extends StatelessWidget {
  const _VerificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(context, width: 150, height: 24),
            const SizedBox(height: 16),
            _skeletonLine(context),
            _skeletonLine(context, width: 250),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(context, width: 120, height: 20),
                  const SizedBox(height: 8),
                  _skeletonLine(context),
                  const SizedBox(height: 4),
                  _skeletonLine(context),
                  const SizedBox(height: 4),
                  _skeletonLine(context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _skeletonLine(context, width: 200, height: 48)),
          ],
        ),
      ),
    );
  }
}

class _QuickLinksCardSkeleton extends StatelessWidget {
  const _QuickLinksCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(context, width: 150, height: 24),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(4, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _skeletonLine(context, width: 80, height: 18),
                      const SizedBox(height: 4),
                      _skeletonLine(context, width: 60, height: 12),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for creating skeleton loading effects
Widget _skeletonLine(
  BuildContext context, {
  double? width,
  double height = 16,
}) {
  return Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
