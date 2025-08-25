// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _startAt = DateTime.now();
  DateTime? _endAt;
  bool _published = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description ?? '';
      _startAt = e.startAt.toDate();
      _endAt = e.endAt?.toDate();
      _published = e.published;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null) return;
    setState(
      () => _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pickEnd() async {
    final base = _endAt ?? _startAt;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    setState(
      () => _endAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Start'),
              subtitle: Text(_startAt.toLocal().toString()),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _pickStart,
              ),
            ),
            ListTile(
              title: const Text('End'),
              subtitle: Text(_endAt?.toLocal().toString() ?? '—'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _pickEnd,
              ),
            ),
            SwitchListTile(
              title: const Text('Published'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        final repo = BusinessRepository(
                          FirebaseFirestore.instance,
                          FirebaseAuth.instance,
                        );
                        final evt = BusinessEvent(
                          id: widget.event?.id ?? '',
                          businessId: widget.businessId,
                          title: _title.text.trim(),
                          description: _description.text.trim().isEmpty
                              ? null
                              : _description.text.trim(),
                          startAt: Timestamp.fromDate(_startAt.toUtc()),
                          endAt: _endAt == null
                              ? null
                              : Timestamp.fromDate(_endAt!.toUtc()),
                          published: _published,
                        );
                        if (widget.event == null) {
                          await repo.createEvent(widget.businessId, evt);
                        } else {
                          await repo.updateEvent(
                            widget.businessId,
                            widget.event!.id,
                            evt.toJson(),
                          );
                        }
                        if (mounted) Navigator.of(context).pop(true);
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
