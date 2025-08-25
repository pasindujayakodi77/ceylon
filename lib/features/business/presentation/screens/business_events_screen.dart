// FILE: lib/features/business/presentation/screens/business_events_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'event_editor_screen.dart';

class BusinessEventsScreen extends StatefulWidget {
  final String businessId;
  const BusinessEventsScreen({super.key, required this.businessId});

  @override
  State<BusinessEventsScreen> createState() => _BusinessEventsScreenState();
}

class _BusinessEventsScreenState extends State<BusinessEventsScreen>
    with TickerProviderStateMixin {
  final _repository = BusinessRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  late TabController _tabController;
  late Stream<List<BusinessEvent>> _eventsStream;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initEventStream();
  }

  void _initEventStream() {
    _eventsStream = _repository.streamEvents(
      widget.businessId,
      includeUnpublished: true,
      limit: 50,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'PAST'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEvent(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BusinessEvent>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initEventStream,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];
          final upcomingEvents = events
              .where((e) => e.startAt.toDate().isAfter(now))
              .toList();

          final pastEvents = events
              .where((e) => e.startAt.toDate().isBefore(now))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventsList(upcomingEvents, isUpcoming: true),
              _buildEventsList(pastEvents, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(
    List<BusinessEvent> events, {
    required bool isUpcoming,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming events' : 'No past events',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Create a new event using the + button'
                  : 'Events that have passed will appear here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          onTap: () => _editEvent(context, event),
          isUpcoming: isUpcoming,
        );
      },
    );
  }

  Future<void> _createEvent(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(businessId: widget.businessId),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      // The stream will update automatically
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
    }
  }

  Future<void> _editEvent(BuildContext context, BusinessEvent event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventEditorScreen(businessId: widget.businessId, event: event),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      // The stream will update automatically
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    }
  }
}

class _EventCard extends StatelessWidget {
  final BusinessEvent event;
  final VoidCallback onTap;
  final bool isUpcoming;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final startDate = event.startAt.toDate().toLocal();
    final endDate = event.endAt?.toDate().toLocal();

    // Format date and time
    final formattedDate = dateFormat.format(startDate);
    final formattedStartTime = timeFormat.format(startDate);
    final formattedEndTime = endDate != null
        ? timeFormat.format(endDate)
        : null;
    final timeDisplay = formattedEndTime != null
        ? '$formattedStartTime - $formattedEndTime'
        : formattedStartTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with visibility status
            Container(
              color: colorScheme.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Time information
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeDisplay,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      event.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final isPublished = event.published;
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isPublished
        ? colorScheme.primary.withOpacity(0.2)
        : colorScheme.error.withOpacity(0.2);

    final textColor = isPublished ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.visibility : Icons.visibility_off,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Public' : 'Draft',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
