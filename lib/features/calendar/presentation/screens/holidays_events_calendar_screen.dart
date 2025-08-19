import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/booking/booking_utils.dart';
import '../../../../dev/seed_calendar_events.dart';
import '../../data/calendar_event.dart';
import '../../data/events_repository.dart';
import '../../data/holiday.dart';
import '../../data/holidays_repository.dart';
import '../widgets/calendar_legend.dart';
import '../widgets/event_list_tile.dart';
import '../../../business/data/business_analytics_service.dart';
import '../../../itinerary/data/itinerary_service.dart';

class HolidaysEventsCalendarScreen extends StatefulWidget {
  const HolidaysEventsCalendarScreen({super.key});

  @override
  State<HolidaysEventsCalendarScreen> createState() =>
      _HolidaysEventsCalendarScreenState();
}

class _HolidaysEventsCalendarScreenState
    extends State<HolidaysEventsCalendarScreen> {
  late final EventsRepository _eventsRepository;
  late final HolidaysRepository _holidaysRepository;

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  // Data state
  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};
  Map<DateTime, List<Holiday>> _holidaysByDay = {};
  List<CalendarEvent> _monthEvents = [];
  final Set<String> _savedEventIds = <String>{}; // Track saved events

  // UI state
  bool _isLoading = true;
  String? _errorMessage;
  // Support multi-select filters via chips and CSV input
  final Set<String> _selectedFilters = <String>{};

  final List<String> _filterOptions = [
    'All',
    'Promotions',
    'Free',
    'Family',
    'Outdoor',
  ];

  bool _routeFiltersApplied = false;

  // Normalize various input aliases to our canonical filter names
  String? _normalizeFilterLabel(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    switch (key) {
      case 'all':
        return 'All';
      case 'promotion':
      case 'promotions':
      case 'promo':
        return 'Promotions';
      case 'free':
        return 'Free';
      case 'family':
        return 'Family';
      case 'outdoor':
      case 'outdoors':
        return 'Outdoor';
      default:
        return null;
    }
  }

  void _applyFiltersFromCsv(String csv) {
    final parts = csv.split(',');
    final normalized = parts
        .map((p) => _normalizeFilterLabel(p))
        .whereType<String>()
        .toSet();
    setState(() {
      _selectedFilters
        ..clear()
        ..addAll(normalized);
      // If 'All' is present with others, keep only 'All'
      if (_selectedFilters.contains('All') && _selectedFilters.length > 1) {
        _selectedFilters
          ..clear()
          ..add('All');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _eventsRepository = EventsRepository();
    _holidaysRepository = HolidaysRepository();
    _loadDataForMonth(_focusedMonth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeFiltersApplied) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['filters'] is String) {
      _applyFiltersFromCsv(args['filters'] as String);
    }
    _routeFiltersApplied = true;
  }

  Future<void> _loadDataForMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate month boundaries
      final monthStart = DateTime(month.year, month.month, 1);
      final nextMonthStart = DateTime(month.year, month.month + 1, 1);

      // Load events and holidays in parallel
      final results = await Future.wait([
        _eventsRepository.fetchMonthEvents(monthStart, nextMonthStart),
        _holidaysRepository.loadHolidaysFromAsset(),
      ]);

      final events = results[0] as List<CalendarEvent>;
      final holidays = results[1] as List<Holiday>;

      // Group by day
      final eventsByDay = await _eventsRepository.groupByDay(events);
      final holidaysByDay = _holidaysRepository.groupByDay(
        holidays
            .where(
              (h) => h.date.year == month.year && h.date.month == month.month,
            )
            .toList(),
      );

      setState(() {
        _monthEvents = events;
        _eventsByDay = eventsByDay;
        _holidaysByDay = holidaysByDay;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        // Check if it's a Firestore index error
        if (error.toString().contains('FAILED_PRECONDITION') &&
            error.toString().contains('requires an index')) {
          _errorMessage =
              'Setting up database indexes... Please try again in a moment.';
        } else {
          _errorMessage = 'Failed to load calendar data: ${error.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  List<CalendarEvent> _getFilteredEvents() {
    // If no filter or 'All' selected, show all
    if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) {
      return _monthEvents;
    }

    bool matchesAnySelected(CalendarEvent event) {
      final isPromotion =
          (event.promoCode != null && event.promoCode!.isNotEmpty) ||
          (event.discountPct != null && event.discountPct! > 0);
      final isFree =
          event.tags.contains('free') ||
          (event.discountPct != null && event.discountPct! >= 100);
      final isFamily = event.tags.contains('family');
      final isOutdoor = event.tags.contains('outdoor');

      for (final f in _selectedFilters) {
        switch (f) {
          case 'Promotions':
            if (isPromotion) return true;
            break;
          case 'Free':
            if (isFree) return true;
            break;
          case 'Family':
            if (isFamily) return true;
            break;
          case 'Outdoor':
            if (isOutdoor) return true;
            break;
        }
      }
      return false;
    }

    return _monthEvents.where(matchesAnySelected).toList();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = _eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
    final holidays =
        _holidaysByDay[DateTime(day.year, day.month, day.day)] ?? [];
    return [...holidays, ...events];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });

    final dayEvents =
        _eventsByDay[DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        )] ??
        [];

    if (dayEvents.isNotEmpty) {
      _showDayEventsBottomSheet(selectedDay, dayEvents);
    }
  }

  void _showDayEventsBottomSheet(DateTime day, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Events on ${DateFormat('EEEE, MMM d').format(day)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

              const SizedBox(height: 16),

              // Events list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return FutureBuilder<Map<String, String?>>(
                      future: _eventsRepository.fetchBusinessMeta(
                        event.businessId,
                      ),
                      builder: (context, businessSnapshot) {
                        final businessMeta = businessSnapshot.data ?? {};
                        final hasPhone =
                            businessMeta['phone']?.isNotEmpty == true;
                        final hasForm =
                            businessMeta['bookingFormUrl']?.isNotEmpty == true;

                        return EventListTile(
                          event: event,
                          onBookWhatsApp: hasPhone
                              ? () => _onBookWhatsApp(event)
                              : null,
                          onOpenForm: hasForm ? () => _onOpenForm(event) : null,
                          onAddToItinerary: () => _onAddToItinerary(event),
                          onToggleSave: () => _onToggleSave(event),
                          isSaved: _savedEventIds.contains(event.businessId),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Callback methods for event actions
  Future<void> _onBookWhatsApp(CalendarEvent event) async {
    try {
      // Fetch business metadata to get phone number
      final businessMeta = await _eventsRepository.fetchBusinessMeta(
        event.businessId,
      );
      final phone = businessMeta['phone'];

      if (phone == null || phone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'WhatsApp number not available for this event',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return;
      }

      // Build WhatsApp message
      final message = 'Inquiry about ${event.title} from CEYLON';

      // Launch WhatsApp
      final success = await openWhatsApp(phone: phone, message: message);

      if (success) {
        // Record analytics
        await BusinessAnalyticsService.instance.recordBookingWhatsApp(
          event.businessId,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening WhatsApp: $e')));
      }
    }
  }

  Future<void> _onOpenForm(CalendarEvent event) async {
    try {
      // Fetch business metadata to get booking form URL
      final businessMeta = await _eventsRepository.fetchBusinessMeta(
        event.businessId,
      );
      final bookingFormUrl = businessMeta['bookingFormUrl'];

      if (bookingFormUrl == null || bookingFormUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking form not available for this event'),
            ),
          );
        }
        return;
      }

      // Launch booking form
      final uri = buildFormUri(bookingFormUrl);
      final success = await openUri(uri);

      if (success) {
        // Record analytics
        await BusinessAnalyticsService.instance.recordBookingForm(
          event.businessId,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open booking form')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening booking form: $e')),
        );
      }
    }
  }

  Future<void> _onAddToItinerary(CalendarEvent event) async {
    try {
      // Use the existing itinerary service to add the event as a holiday item
      // This is a simplified implementation - in a real app you might want to
      // show a dialog to select which itinerary to add to
      final itineraryId = await _showItinerarySelectionDialog(event);

      if (itineraryId != null) {
        await ItineraryService.instance.addHolidayItem(
          itineraryId: itineraryId,
          date: event.startsAt,
          countryCode: 'LK', // Assuming Sri Lanka
          holidayName: event.title,
          note: event.description,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added to itinerary')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to itinerary: $e')),
        );
      }
    }
  }

  Future<String?> _showItinerarySelectionDialog(CalendarEvent event) async {
    // TODO: In a real implementation, you would show a dialog to select from existing itineraries
    // For now, we'll create a new itinerary automatically
    try {
      final newItineraryId = await ItineraryService.instance.createItinerary(
        'Events from CEYLON Calendar',
      );
      return newItineraryId;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onToggleSave(CalendarEvent event) async {
    try {
      // Toggle saved state locally
      setState(() {
        if (_savedEventIds.contains(event.businessId)) {
          _savedEventIds.remove(event.businessId);
        } else {
          _savedEventIds.add(event.businessId);
        }
      });

      // Store event favorites in a separate collection for events
      final eventRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('favorite_events')
          .doc(event.businessId);

      if (_savedEventIds.contains(event.businessId)) {
        // Add to favorites
        await eventRef.set({
          'businessId': event.businessId,
          'title': event.title,
          'startsAt': event.startsAt,
          'saved_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Remove from favorites
        await eventRef.delete();
      }

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _savedEventIds.contains(event.businessId)
                  ? 'Event saved to favorites'
                  : 'Event removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert state change if save failed
      setState(() {
        if (_savedEventIds.contains(event.businessId)) {
          _savedEventIds.remove(event.businessId);
        } else {
          _savedEventIds.add(event.businessId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Debug-only method to seed demo calendar events
  Future<void> _seedDemoEvents() async {
    if (!kDebugMode) return;

    try {
      setState(() => _isLoading = true);

      await CalendarEventSeeder.seedDemoEvents();

      // Reload data to show the new events
      await _loadDataForMonth(_focusedMonth);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demo events seeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to seed demo events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDataForMonth(_focusedMonth);
  }

  Widget _buildCalendarSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Legend skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Calendar grid skeleton
          Flexible(
            child: SizedBox(
              height: 300, // Fixed height for skeleton
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: 42, // 6 weeks x 7 days
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title skeleton
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Description skeleton
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 16),
              // Button skeletons
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays & Events'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // Debug-only seeder button
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Seed demo events',
              onPressed: _seedDemoEvents,
            ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _focusedMonth = today;
                _selectedDay = today;
              });
              _loadDataForMonth(today);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Error banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                color: colorScheme.errorContainer,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _loadDataForMonth(_focusedMonth),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            // Calendar section
            if (_isLoading)
              Expanded(flex: 2, child: _buildCalendarSkeleton())
            else
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Calendar legend
                    const CalendarLegend(),
                    const SizedBox(
                      height: 8,
                    ), // Add spacing between legend and calendar
                    // Table calendar
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 450, // Increased to fix overflow issue
                        ),
                        child: TableCalendar<dynamic>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedMonth,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                          },
                          // Styling
                          // Make calendar more compact
                          rowHeight:
                              34, // Reduced row height to prevent overflow
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            markersMaxCount: 2,
                            markerDecoration: BoxDecoration(
                              color: colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            holidayDecoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            selectedDecoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            // Improve text contrast for dark mode
                            defaultTextStyle: TextStyle(
                              color: colorScheme.onSurface,
                            ),
                            weekendTextStyle: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            holidayTextStyle: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedTextStyle: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            todayTextStyle: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            outsideTextStyle: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),

                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: colorScheme.onSurface,
                              size: 28,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurface,
                              size: 28,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                            ),
                          ),

                          onDaySelected: _onDaySelected,
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedMonth = focusedDay;
                            });
                            _loadDataForMonth(focusedDay);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom section: Upcoming this month
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header and filter chips
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            'Upcoming this month',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter chips
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filterOptions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final option = _filterOptions[index];
                              final bool isSelected = option == 'All'
                                  ? (_selectedFilters.isEmpty ||
                                        _selectedFilters.contains('All'))
                                  : _selectedFilters.contains(option);
                              return FilterChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (option == 'All') {
                                      // Selecting 'All' clears other selections
                                      _selectedFilters
                                        ..clear()
                                        ..add('All');
                                    } else {
                                      // Toggle this option
                                      if (_selectedFilters.contains(option)) {
                                        _selectedFilters.remove(option);
                                      } else {
                                        _selectedFilters.add(option);
                                      }
                                      // If any specific filters are selected, 'All' should not be selected
                                      if (_selectedFilters.isNotEmpty) {
                                        _selectedFilters.remove('All');
                                      }
                                      // If nothing is selected, treat as 'All' (empty set is fine)
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Events list
                  Flexible(
                    child: _isLoading
                        ? _buildEventsListSkeleton()
                        : _buildEventsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final filteredEvents = _getFilteredEvents()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (filteredEvents.isEmpty) {
      final bool showingAll =
          _selectedFilters.isEmpty || _selectedFilters.contains('All');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showingAll ? Icons.calendar_month_outlined : Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Text(
                showingAll
                    ? 'No events scheduled this month'
                    : 'No selected-filter events this month',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                'Pull down to refresh or try a different filter',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return EventListTile(
          event: event,
          onBookWhatsApp: () => _onBookWhatsApp(event),
          onOpenForm: () => _onOpenForm(event),
          onAddToItinerary: () => _onAddToItinerary(event),
          onToggleSave: () => _onToggleSave(event),
          isSaved: false, // TODO: Implement save state
        );
      },
    );
  }
}
