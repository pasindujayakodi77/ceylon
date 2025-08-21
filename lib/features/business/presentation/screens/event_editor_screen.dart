import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventEditorScreen extends StatefulWidget {
  final String businessId;
  final String? eventId; // null -> create, not null -> edit
  final Map<String, dynamic>? initialData;

  const EventEditorScreen({
    super.key,
    required this.businessId,
    this.eventId,
    this.initialData,
  });

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bannerCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController(); // comma-separated tags

  DateTime? _start;
  DateTime? _end;
  bool _published = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _titleCtrl.text = d['title'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _bannerCtrl.text = d['banner'] ?? '';
      _promoCtrl.text = d['promoCode'] ?? '';
      _discountCtrl.text = (d['discountPct']?.toString() ?? '');
      _cityCtrl.text = d['city'] ?? '';
      final tags = (d['tags'] as List?)?.whereType<String>().toList() ?? [];
      if (tags.isNotEmpty) {
        _tagsCtrl.text = tags.join(', ');
      }
      _published = (d['published'] as bool?) ?? false;
      _start = (d['startsAt'] as Timestamp?)?.toDate();
      _end = (d['endsAt'] as Timestamp?)?.toDate();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _bannerCtrl.dispose();
    _promoCtrl.dispose();
    _discountCtrl.dispose();
    _cityCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start ?? now),
    );
    if (!mounted) return;
    setState(
      () => _start = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _pickEnd() async {
    final base = _start ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _end ?? base.add(const Duration(hours: 2)),
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 3),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _end ?? base.add(const Duration(hours: 2)),
      ),
    );
    if (!mounted) return;
    setState(
      () => _end = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select start and end time')),
        );
      }
      return;
    }
    if (_end!.isBefore(_start!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    // Validate discount percentage if provided (allow decimals)
    double? discount;
    final discountText = _discountCtrl.text.trim();
    if (discountText.isNotEmpty) {
      discount = double.tryParse(discountText);
      if (discount == null || discount < 0 || discount > 100) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Discount % must be a number between 0 and 100'),
            ),
          );
        }
        return;
      }
    }

    // Parse tags from CSV (comma separated)
    final tags = _tagsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final common = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'banner': _bannerCtrl.text.trim(),
      'promoCode': _promoCtrl.text.trim(),
      'discountPct': discount,
      'startsAt': Timestamp.fromDate(_start!),
      'endsAt': Timestamp.fromDate(_end!),
      'published': _published,
      'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      'tags': tags,
      'businessId': widget.businessId,
    };

    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events');

    if (widget.eventId == null) {
      await ref.add({
        ...common,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Do not overwrite createdAt on updates; only touch updatedAt
      await ref.doc(widget.eventId).set({
        ...common,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = () {
      if (_start == null || _end == null) return 'Pick dates';
      final s = _start!.toLocal().toString().split('.').first;
      final e = _end!.toLocal().toString().split('.').first;
      return '$s → $e';
    }();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventId == null ? 'Add Event / Promotion' : 'Edit Event',
        ),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bannerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Banner Image URL (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma-separated, optional)',
                        helperText: 'e.g., wildlife, ocean, sunset, tour',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _promoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Promo Code (optional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Discount % (0–100)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date & Time'),
                      subtitle: Text(dateText),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickStart,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickEnd,
                            icon: const Icon(Icons.stop),
                            label: const Text('End'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Published (visible to users)'),
                      value: _published,
                      onChanged: (v) => setState(() => _published = v),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
