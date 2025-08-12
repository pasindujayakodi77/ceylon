import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:ceylon/features/itinerary/data/itinerary_model.dart';
import 'package:ceylon/features/itinerary/data/itinerary_repository.dart';
import 'package:ceylon/features/itinerary/presentation/widgets/itinerary_day_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ItineraryBuilderScreen extends StatefulWidget {
  final String? itineraryId;

  const ItineraryBuilderScreen({super.key, this.itineraryId});

  @override
  State<ItineraryBuilderScreen> createState() => _ItineraryBuilderScreenState();
}

class _ItineraryBuilderScreenState extends State<ItineraryBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  late Itinerary _itinerary;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;

  late ItineraryRepository _itineraryRepository;

  // Helper method to convert model ItineraryDay to adapter ItineraryDay
  adapter.ItineraryDay _convertModelDayToAdapter(ItineraryDay modelDay) {
    final adapterItems = modelDay.items.map((modelItem) {
      return adapter.ItineraryItem(
        id: modelItem.id ?? '',
        title: modelItem.title,
        startTime: DateTime(
          2024,
          1,
          1,
          modelItem.startTime.hour,
          modelItem.startTime.minute,
        ),
        durationMinutes: modelItem.endTime != null
            ? (modelItem.endTime!.hour * 60 + modelItem.endTime!.minute) -
                  (modelItem.startTime.hour * 60 + modelItem.startTime.minute)
            : 60,
        note: modelItem.description,
        placeId: modelItem.attractionId,
        imageUrl: modelItem.imageUrl,
        latitude: modelItem.latitude,
        longitude: modelItem.longitude,
        description: modelItem.description,
        locationName: modelItem.locationName,
        cost: modelItem.cost,
        type: _convertModelTypeToAdapter(modelItem.type),
        attractionId: modelItem.attractionId,
      );
    }).toList();

    return adapter.ItineraryDay(
      id: modelDay.id ?? '',
      dayName: modelDay.dayName,
      date: modelDay.date,
      formattedDate: modelDay.formattedDate,
      items: adapterItems,
      note: modelDay.note,
    );
  }

  adapter.ItineraryItemType _convertModelTypeToAdapter(
    ItineraryItemType modelType,
  ) {
    switch (modelType) {
      case ItineraryItemType.attraction:
        return adapter.ItineraryItemType.attraction;
      case ItineraryItemType.activity:
        return adapter.ItineraryItemType.activity;
      case ItineraryItemType.meal:
        return adapter.ItineraryItemType.meal;
      case ItineraryItemType.accommodation:
        return adapter.ItineraryItemType.accommodation;
      case ItineraryItemType.transportation:
        return adapter.ItineraryItemType.transportation;
      default:
        return adapter.ItineraryItemType.other;
    }
  }

  // Update the items list with a converted adapter item
  void _updateModelItemFromAdapter(
    adapter.ItineraryItem adapterItem,
    int dayIndex,
    int itemIndex,
  ) {
    final modelItem = ItineraryItem(
      id: adapterItem.id,
      title: adapterItem.title,
      description: adapterItem.description,
      startTime: TimeOfDay(
        hour: adapterItem.startTime.hour,
        minute: adapterItem.startTime.minute,
      ),
      endTime: adapterItem.endTime,
      type: _convertAdapterTypeToModel(adapterItem.type),
      locationName: adapterItem.locationName,
      latitude: adapterItem.latitude,
      longitude: adapterItem.longitude,
      attractionId: adapterItem.attractionId,
      cost: adapterItem.cost,
      imageUrl: adapterItem.imageUrl,
    );

    final day = _itinerary.days[dayIndex];
    final updatedItems = [...day.items];
    updatedItems[itemIndex] = modelItem;

    final updatedDay = day.copyWith(items: updatedItems);
    final updatedDays = [..._itinerary.days];
    updatedDays[dayIndex] = updatedDay;

    setState(() {
      _itinerary = _itinerary.copyWith(days: updatedDays);
    });
  }

  ItineraryItemType _convertAdapterTypeToModel(
    adapter.ItineraryItemType adapterType,
  ) {
    switch (adapterType) {
      case adapter.ItineraryItemType.attraction:
        return ItineraryItemType.attraction;
      case adapter.ItineraryItemType.activity:
        return ItineraryItemType.activity;
      case adapter.ItineraryItemType.meal:
        return ItineraryItemType.meal;
      case adapter.ItineraryItemType.accommodation:
        return ItineraryItemType.accommodation;
      case adapter.ItineraryItemType.transportation:
        return ItineraryItemType.transportation;
      default:
        return ItineraryItemType.other;
    }
  }

  Itinerary _convertAdapterToModel(adapter.Itinerary adapterItinerary) {
    // Create a new model Itinerary using data from adapter
    List<ItineraryDay> days = [];

    for (var adapterDay in adapterItinerary.days) {
      List<ItineraryItem> items = [];

      // Convert each item
      for (var adapterItem in adapterDay.items) {
        final startTime = TimeOfDay(
          hour: adapterItem.startTime.hour,
          minute: adapterItem.startTime.minute,
        );

        items.add(
          ItineraryItem(
            id: adapterItem.id,
            title: adapterItem.title,
            description: adapterItem.note,
            startTime: startTime,
            type: ItineraryItemType.activity,
            locationName: null,
            imageUrl: adapterItem.imageUrl,
          ),
        );
      }

      // Create day
      days.add(
        ItineraryDay(
          id: adapterDay.id,
          date: adapterDay.date,
          items: items,
          note: adapterDay.note,
        ),
      );
    }

    return Itinerary(
      id: adapterItinerary.id,
      title: adapterItinerary.title,
      description: adapterItinerary.description,
      startDate: adapterItinerary.startDate,
      days: days,
      userId: adapterItinerary.userId,
      createdAt: adapterItinerary.createdAt,
      updatedAt: adapterItinerary.updatedAt,
    );
  }

  // Convert from model Itinerary to adapter Itinerary
  adapter.Itinerary _convertModelToAdapter(Itinerary modelItinerary) {
    List<adapter.ItineraryDay> days = [];

    for (var modelDay in modelItinerary.days) {
      List<adapter.ItineraryItem> items = [];

      // Convert each item
      for (var modelItem in modelDay.items) {
        // Convert TimeOfDay to DateTime
        final DateTime itemTime = DateTime(
          2022,
          1,
          1, // Dummy date
          modelItem.startTime.hour,
          modelItem.startTime.minute,
        );

        items.add(
          adapter.ItineraryItem(
            id: modelItem.id ?? const Uuid().v4(),
            title: modelItem.title,
            startTime: itemTime,
            durationMinutes: 60, // Default duration
            note: modelItem.description,
            imageUrl: modelItem.imageUrl,
            latitude: modelItem.latitude,
            longitude: modelItem.longitude,
          ),
        );
      }

      // Create day with formatted date string
      final formatter = DateFormat('MMM d, yyyy');
      days.add(
        adapter.ItineraryDay(
          id: modelDay.id ?? const Uuid().v4(),
          dayName: modelDay.note ?? "Day",
          date: modelDay.date,
          formattedDate: formatter.format(modelDay.date),
          items: items,
          note: modelDay.note,
        ),
      );
    }

    return adapter.Itinerary(
      id: modelItinerary.id ?? const Uuid().v4(),
      title: modelItinerary.title,
      description: modelItinerary.description,
      startDate: modelItinerary.startDate,
      endDate: modelItinerary.endDate,
      days: days,
      userId: modelItinerary.userId,
      createdAt: modelItinerary.createdAt,
      updatedAt: modelItinerary.updatedAt ?? DateTime.now(),
      destination: "Sri Lanka", // Default destination
    );
  }

  // Method to get attractions data for the itinerary
  Future<List<Attraction>> _getAttractions() async {
    // Use mock data from adapter
    return adapter.ItineraryAdapter.getMockAttractions();
  }

  @override
  void initState() {
    super.initState();
    _itineraryRepository = Provider.of<ItineraryRepository>(
      context,
      listen: false,
    );
    _isEditing = widget.itineraryId != null;

    if (_isEditing) {
      _loadExistingItinerary();
    } else {
      _initializeNewItinerary();
    }
  }

  Future<void> _loadExistingItinerary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adapterItinerary = await _itineraryRepository.getItineraryById(
        widget.itineraryId!,
      );

      // Convert from adapter model to app model
      final modelItinerary = _convertAdapterToModel(adapterItinerary);

      setState(() {
        _itinerary = modelItinerary;
        _titleController.text = modelItinerary.title;
        _destinationController.text = ""; // Destination not available in model

        // Set dates directly from the model
        _startDate = modelItinerary.startDate;
        _endDate = modelItinerary.endDate;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load itinerary: $e';
        _isLoading = false;
        _initializeNewItinerary(); // Create a new one as fallback
      });
    }
  }

  void _initializeNewItinerary() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _errorMessage = 'You need to be logged in to create an itinerary';
      return;
    }

    // Create initial days based on date range
    final days = <ItineraryDay>[];
    final daysBetween = _endDate.difference(_startDate).inDays + 1;

    for (int i = 0; i < daysBetween; i++) {
      final date = _startDate.add(Duration(days: i));
      final dayItems = <ItineraryItem>[];

      days.add(
        ItineraryDay(
          id: const Uuid().v4(),
          date: date,
          items: dayItems,
          note: i == 0
              ? 'Arrival Day'
              : i == daysBetween - 1
              ? 'Departure Day'
              : 'Day ${i + 1}',
        ),
      );
    }

    _itinerary = Itinerary(
      id: widget.itineraryId ?? const Uuid().v4(),
      userId: userId,
      title: '',
      description: '',
      startDate: _startDate,
      days: days,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateDaysBasedOnDateRange();
      });
    }
  }

  void _updateDaysBasedOnDateRange() {
    final daysBetween = _endDate.difference(_startDate).inDays + 1;

    // Update itinerary start date - endDate is calculated automatically
    _itinerary = _itinerary.copyWith(startDate: _startDate);

    // If days count changed, adjust days list
    if (_itinerary.days.length != daysBetween) {
      final List<ItineraryDay> newDays = [];

      // Keep existing days that are still in range
      for (int i = 0; i < daysBetween; i++) {
        final date = _startDate.add(Duration(days: i));
        final note = i == 0
            ? 'Arrival Day'
            : i == daysBetween - 1
            ? 'Departure Day'
            : 'Day ${i + 1}';

        if (i < _itinerary.days.length) {
          // Update day with new date
          final existingDay = _itinerary.days[i];
          newDays.add(existingDay.copyWith(date: date, note: note));
        } else {
          // Add new day
          newDays.add(
            ItineraryDay(
              id: const Uuid().v4(),
              date: date,
              note: note,
              items: [],
            ),
          );
        }
      }

      setState(() {
        _itinerary = _itinerary.copyWith(days: newDays);
      });
    }
  }

  Future<void> _saveItinerary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Update title from controllers
      final updatedItinerary = _itinerary.copyWith(
        title: _titleController.text,
        description: _destinationController.text,
        updatedAt: DateTime.now(),
      );

      // Convert from model to adapter before saving
      final adapterItinerary = _convertModelToAdapter(updatedItinerary);

      if (_isEditing) {
        await _itineraryRepository.updateItinerary(adapterItinerary);
      } else {
        await _itineraryRepository.createItinerary(adapterItinerary);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Itinerary ${_isEditing ? 'updated' : 'created'} successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save itinerary: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addItineraryItem(ItineraryDay day) async {
    final attractions = await _getAttractions();

    if (!mounted) return;

    final TimeOfDay initialTime = TimeOfDay(
      hour: 9 + (day.items.length % 8), // Spread activities throughout the day
      minute: 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return _AddItineraryItemSheet(
              day: day,
              attractions: attractions,
              initialTime: initialTime,
              onAddItem: (ItineraryItem newItem) {
                // Find day index
                final dayIndex = _itinerary.days.indexWhere(
                  (d) => d.id == day.id,
                );
                if (dayIndex == -1) return;

                // Add new item to day
                final updatedDay = _itinerary.days[dayIndex].copyWith(
                  items: [..._itinerary.days[dayIndex].items, newItem],
                );

                // Update itinerary with modified day
                final updatedDays = [..._itinerary.days];
                updatedDays[dayIndex] = updatedDay;

                setState(() {
                  _itinerary = _itinerary.copyWith(days: updatedDays);
                });
              },
            );
          },
        );
      },
    );
  }

  void _editDayNote(ItineraryDay day) {
    final noteController = TextEditingController(text: day.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Day Notes'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Add notes for this day...',
          ),
          minLines: 3,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);

              // Find day index
              final dayIndex = _itinerary.days.indexWhere(
                (d) => d.id == day.id,
              );
              if (dayIndex == -1) return;

              // Update day with new note
              final updatedDay = _itinerary.days[dayIndex].copyWith(
                note: noteController.text,
              );

              // Update itinerary
              final updatedDays = [..._itinerary.days];
              updatedDays[dayIndex] = updatedDay;

              setState(() {
                _itinerary = _itinerary.copyWith(days: updatedDays);
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editItineraryItem(adapter.ItineraryItem item) {
    // Find which day contains this item
    int dayIndex = -1;
    int itemIndex = -1;

    for (int i = 0; i < _itinerary.days.length; i++) {
      final idx = _itinerary.days[i].items.indexWhere((it) => it.id == item.id);
      if (idx != -1) {
        dayIndex = i;
        itemIndex = idx;
        break;
      }
    }

    if (dayIndex == -1 || itemIndex == -1) return;

    // Set up controllers
    final titleController = TextEditingController(text: item.title);
    final noteController = TextEditingController(text: item.note ?? "");
    TimeOfDay timeOfDay = TimeOfDay(
      hour: item.startTime.hour,
      minute: item.startTime.minute,
    );
    int durationMinutes = item.durationMinutes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Activity'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Title',
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                  const Text('Start Time'),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: timeOfDay,
                      );
                      if (picked != null) {
                        setState(() {
                          timeOfDay = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeOfDay.format(context),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                  const Text('Duration'),
                  Slider(
                    value: durationMinutes.toDouble(),
                    min: 15,
                    max: 240,
                    divisions: 15,
                    label: _formatDuration(durationMinutes),
                    onChanged: (value) {
                      setState(() {
                        durationMinutes = value.toInt();
                      });
                    },
                  ),
                  Center(child: Text(_formatDuration(durationMinutes))),
                  const SizedBox(height: CeylonTokens.spacing16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add any additional information...',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  // Update the item using the conversion method
                  final updatedAdapterItem = item.copyWith(
                    title: titleController.text,
                    startTime: DateTime(
                      2024,
                      1,
                      1,
                      timeOfDay.hour,
                      timeOfDay.minute,
                    ),
                    note: noteController.text,
                    durationMinutes: durationMinutes,
                  );

                  // Convert and update
                  _updateModelItemFromAdapter(
                    updatedAdapterItem,
                    dayIndex,
                    itemIndex,
                  );

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteItineraryItem(adapter.ItineraryItem item) {
    // Find which day contains this item
    int dayIndex = -1;

    for (int i = 0; i < _itinerary.days.length; i++) {
      if (_itinerary.days[i].items.any((it) => it.id == item.id)) {
        dayIndex = i;
        break;
      }
    }

    if (dayIndex == -1) return;

    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to remove "${item.title}" from your itinerary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Remove item
              final day = _itinerary.days[dayIndex];
              final updatedItems = day.items
                  .where((it) => it.id != item.id)
                  .toList();

              final updatedDay = day.copyWith(items: updatedItems);
              final updatedDays = [..._itinerary.days];
              updatedDays[dayIndex] = updatedDay;

              setState(() {
                _itinerary = _itinerary.copyWith(days: updatedDays);
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewPlace(adapter.ItineraryItem item) {
    if (item.attractionId != null && item.attractionId!.isNotEmpty) {
      // Navigate to place details
      Navigator.pushNamed(context, '/place/${item.attractionId}');
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Itinerary' : 'Create Itinerary'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Itinerary' : 'Create Itinerary'),
        actions: [
          TextButton.icon(
            onPressed: _saveItinerary,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    _errorMessage!,
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CeylonTokens.spacing24),
                  ElevatedButton(
                    onPressed: _isEditing
                        ? _loadExistingItinerary
                        : _initializeNewItinerary,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(CeylonTokens.spacing16),
                children: [
                  // Basic details section
                  Card(
                    margin: const EdgeInsets.only(
                      bottom: CeylonTokens.spacing16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(CeylonTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: CeylonTokens.spacing16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Trip Title',
                              hintText: 'Summer Vacation 2023',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CeylonTokens.spacing16),
                          TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              labelText: 'Destination',
                              hintText: 'Paris, France',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a destination';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CeylonTokens.spacing16),
                          // Date range selector
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(
                              CeylonTokens.radiusMedium,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                CeylonTokens.spacing16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.outline),
                                borderRadius: BorderRadius.circular(
                                  CeylonTokens.radiusMedium,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: CeylonTokens.spacing12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip Dates',
                                          style: textTheme.labelMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                                          style: textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_endDate.difference(_startDate).inDays + 1} days',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Itinerary days
                  ...List.generate(_itinerary.days.length, (index) {
                    final day = _itinerary.days[index];
                    final adapterDay = _convertModelDayToAdapter(day);
                    return ItineraryDayWidget(
                      day: adapterDay,
                      dayNumber: index + 1,
                      onAddItem: () => _addItineraryItem(day),
                      onEditNote: () => _editDayNote(day),
                      onItemTap: _viewPlace,
                      onItemEdit: _editItineraryItem,
                      onItemDelete: _deleteItineraryItem,
                    );
                  }),

                  const SizedBox(height: CeylonTokens.spacing16),

                  // Save button
                  FilledButton(
                    onPressed: _saveItinerary,
                    child: Text(
                      _isEditing ? 'Update Itinerary' : 'Create Itinerary',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AddItineraryItemSheet extends StatefulWidget {
  final ItineraryDay day;
  final List<Attraction> attractions;
  final TimeOfDay initialTime;
  final Function(ItineraryItem) onAddItem;

  const _AddItineraryItemSheet({
    required this.day,
    required this.attractions,
    required this.initialTime,
    required this.onAddItem,
  });

  @override
  State<_AddItineraryItemSheet> createState() => _AddItineraryItemSheetState();
}

class _AddItineraryItemSheetState extends State<_AddItineraryItemSheet> {
  String _searchQuery = '';
  Attraction? _selectedAttraction;
  int _durationMinutes = 60;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  final _noteController = TextEditingController();
  final _customTitleController = TextEditingController();
  bool _isCustomActivity = false;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialTime;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  List<Attraction> get _filteredAttractions {
    if (_searchQuery.isEmpty) {
      return widget.attractions;
    }

    final query = _searchQuery.toLowerCase();
    return widget.attractions.where((attraction) {
      return attraction.name.toLowerCase().contains(query) ||
          attraction.category.toLowerCase().contains(query) ||
          attraction.description.toLowerCase().contains(query);
    }).toList();
  }

  void _selectAttraction(Attraction attraction) {
    setState(() {
      _selectedAttraction = attraction;
      _isCustomActivity = false;
    });
  }

  void _toggleCustomActivity() {
    setState(() {
      _isCustomActivity = true;
      _selectedAttraction = null;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes min';
    }
  }

  void _addItem() {
    String title;
    String? imageUrl;
    double? latitude;
    double? longitude;

    if (_isCustomActivity) {
      title = _customTitleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an activity title')),
        );
        return;
      }
    } else if (_selectedAttraction != null) {
      title = _selectedAttraction!.name;
      imageUrl = _selectedAttraction!.imageUrl;
      latitude = _selectedAttraction!.latitude;
      longitude = _selectedAttraction!.longitude;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an attraction or create a custom activity',
          ),
        ),
      );
      return;
    }

    final newItem = ItineraryItem(
      id: const Uuid().v4(),
      title: title,
      description: _noteController.text.trim(),
      startTime: _startTime,
      type: ItineraryItemType.activity,
      locationName: null,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
    );

    widget.onAddItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing16,
            vertical: CeylonTokens.spacing8,
          ),
          child: Text(
            'Add Activity to ${widget.day.dayName}',
            style: textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: _selectedAttraction != null || _isCustomActivity
              ? _buildActivityDetailsForm()
              : _buildAttractionsSelectionList(),
        ),
      ],
    );
  }

  Widget _buildAttractionsSelectionList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(CeylonTokens.spacing16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search places',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        CeylonTokens.radiusMedium,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Custom Activity',
                onPressed: _toggleCustomActivity,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: CeylonTokens.spacing16,
            ),
            itemCount: _filteredAttractions.length,
            itemBuilder: (context, index) {
              final attraction = _filteredAttractions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: CeylonTokens.spacing12),
                child: InkWell(
                  onTap: () => _selectAttraction(attraction),
                  borderRadius: BorderRadius.circular(
                    CeylonTokens.radiusMedium,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CeylonTokens.spacing12),
                    child: Row(
                      children: [
                        if (attraction.imageUrl != null &&
                            attraction.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              CeylonTokens.radiusSmall,
                            ),
                            child: Image.network(
                              attraction.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                CeylonTokens.radiusSmall,
                              ),
                            ),
                            child: const Icon(Icons.place),
                          ),
                        const SizedBox(width: CeylonTokens.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attraction.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                attraction.category,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.add),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDetailsForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(CeylonTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCustomActivity)
            TextField(
              controller: _customTitleController,
              decoration: const InputDecoration(
                labelText: 'Activity Title',
                hintText: 'Enter the activity name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            )
          else if (_selectedAttraction != null)
            Card(
              margin: const EdgeInsets.symmetric(
                vertical: CeylonTokens.spacing8,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child:
                      _selectedAttraction!.imageUrl != null &&
                          _selectedAttraction!.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusSmall,
                          ),
                          child: Image.network(
                            _selectedAttraction!.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                      CeylonTokens.radiusSmall,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.place,
                                    color: colorScheme.primary,
                                  ),
                                ),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              CeylonTokens.radiusSmall,
                            ),
                          ),
                          child: Icon(Icons.place, color: colorScheme.primary),
                        ),
                ),
                title: Text(_selectedAttraction!.name),
                subtitle: Text(_selectedAttraction!.category),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedAttraction = null;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: CeylonTokens.spacing16),
          const Text('Start Time'),
          InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: CeylonTokens.spacing12,
                horizontal: CeylonTokens.spacing16,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
              ),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startTime.format(context),
                    style: textTheme.titleMedium,
                  ),
                  const Icon(Icons.access_time),
                ],
              ),
            ),
          ),
          const SizedBox(height: CeylonTokens.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration: ${_formatDuration(_durationMinutes)}'),
              Text('${_durationMinutes} min'),
            ],
          ),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            onChanged: (value) {
              setState(() {
                _durationMinutes = value.toInt();
              });
            },
          ),
          const SizedBox(height: CeylonTokens.spacing16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Add any additional information...',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 5,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: CeylonTokens.spacing8),
              FilledButton(
                onPressed: _addItem,
                child: const Text('Add to Itinerary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
