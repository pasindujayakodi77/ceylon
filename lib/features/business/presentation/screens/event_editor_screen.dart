// FILE: lib/features/business/presentation/screens/event_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

class EventEditorScreen extends StatefulWidget {
  final String businessId;
  final BusinessEvent? event;
  const EventEditorScreen({super.key, required this.businessId, this.event});

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  late final BusinessRepository _repository;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _published = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  final _dateFormat = DateFormat('MMM d, y');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _repository = BusinessRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    _initializeFields();
  }

  void _initializeFields() {
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';

      // Add these fields to the event model in a real implementation
      // For now, use empty strings or default values
      _imageUrlController.text = '';
      _priceController.text = '';
      _capacityController.text = '';

      final startDateTime = event.startAt.toDate().toLocal();
      _startDate = startDateTime;
      _startTime = TimeOfDay.fromDateTime(startDateTime);

      if (event.endAt != null) {
        final endDateTime = event.endAt!.toDate().toLocal();
        _endDate = endDateTime;
        _endTime = TimeOfDay.fromDateTime(endDateTime);
      }

      _published = event.published;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    // First select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null) return;
    // Ensure widget is still mounted before continuing
    if (!mounted) return;

    // Then select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime == null) return;

    // Ensure widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _startDate = pickedDate;
      _startTime = pickedTime;

      // If end date exists but is before the new start date, update it
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  } // This method is now incorporated in the _selectStartDate method
  // Which handles both date and time selection

  Future<void> _selectEndDate() async {
    // First select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    // Ensure widget is still mounted before continuing
    if (!mounted) return;

    // Then select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );

    if (pickedTime == null) return;

    // Ensure widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _endDate = pickedDate;
      _endTime = pickedTime;
    });
  } // This method is now incorporated in the _selectEndDate method
  // Which handles both date and time selection

  // Combine start date and time to a DateTime object
  DateTime _getStartDateTime() {
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  // Combine end date and time to a DateTime object if both exist
  DateTime? _getEndDateTime() {
    if (_endDate == null || _endTime == null) return null;

    return DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Create the event object
      final startDateTime = _getStartDateTime();
      final endDateTime = _getEndDateTime();

      final event = BusinessEvent(
        id: widget.event?.id ?? '',
        businessId: widget.businessId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startAt: Timestamp.fromDate(startDateTime),
        endAt: endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
        published: _published,
      );

      // Save the event
      if (widget.event == null) {
        await _repository.upsertEvent(widget.businessId, event);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        await _repository.upsertEvent(widget.businessId, event);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save event: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.event == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'This action cannot be undone. The event will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await _repository.deleteEvent(widget.businessId, widget.event!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    return '${_dateFormat.format(dateTime)} at ${_timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: _isDeleting ? null : _deleteEvent,
              tooltip: 'Delete Event',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Event title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/image.jpg',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final isValidUrl = Uri.tryParse(value)?.hasScheme ?? false;
                  if (!isValidUrl) {
                    return 'Please enter a valid URL';
                  }

                  final isImage =
                      value.toLowerCase().endsWith('.jpg') ||
                      value.toLowerCase().endsWith('.jpeg') ||
                      value.toLowerCase().endsWith('.png') ||
                      value.toLowerCase().endsWith('.gif') ||
                      value.toLowerCase().endsWith('.webp');

                  if (!isImage) {
                    return 'URL must point to an image file';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date and Time Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Start Date & Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDateTime(_startDate, _startTime),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _selectStartDate,
                                    child: const Text('CHANGE'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    // End Date & Time (Optional)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_busy),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End (Optional)'),
                              const SizedBox(height: 4),
                              if (_endDate != null && _endTime != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(_endDate!, _endTime!),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _selectEndDate,
                                      child: const Text('CHANGE'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() {
                                        _endDate = null;
                                        _endTime = null;
                                      }),
                                      tooltip: 'Clear end date/time',
                                    ),
                                  ],
                                )
                              else
                                TextButton.icon(
                                  onPressed: _selectEndDate,
                                  icon: const Icon(Icons.add),
                                  label: const Text('ADD END DATE/TIME'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Price & Capacity Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Details (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'Leave empty if free',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final price = double.tryParse(value);
                          if (price == null) {
                            return 'Please enter a valid price';
                          }
                          if (price < 0) {
                            return 'Price cannot be negative';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Capacity
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Capacity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                        hintText: 'Number of attendees',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final capacity = int.tryParse(value);
                          if (capacity == null) {
                            return 'Please enter a valid number';
                          }
                          if (capacity <= 0) {
                            return 'Capacity must be greater than 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Published toggle
            SwitchListTile(
              title: const Text('Publish Event'),
              subtitle: Text(
                _published
                    ? 'Event is visible to users'
                    : 'Event is hidden (draft mode)',
              ),
              value: _published,
              onChanged: (value) => setState(() => _published = value),
              secondary: Icon(
                _published ? Icons.visibility : Icons.visibility_off,
                color: _published ? colorScheme.primary : null,
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isSaving ? null : _saveEvent,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : Text(isEditing ? 'Update Event' : 'Create Event'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
