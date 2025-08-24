// FILE: lib/features/itinerary/presentation/screens/itinerary_builder_screen_new.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/itinerary_routes.dart';
import '../widgets/itinerary_day_widget.dart';

class ItineraryBuilderScreenNew extends StatefulWidget {
  final ItineraryBuilderArgs? args;
  const ItineraryBuilderScreenNew({super.key, this.args});

  @override
  State<ItineraryBuilderScreenNew> createState() =>
      _ItineraryBuilderScreenNewState();
}

class _ItineraryBuilderScreenNewState extends State<ItineraryBuilderScreenNew> {
  String? _itineraryId;
  final _nameCtrl = TextEditingController();
  DateTime _start = DateTime.now();
  int _dayCount = 3;

  final _page = PageController(viewportFraction: 0.98);
  int _currentDay = 1;

  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('itineraries');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = widget.args?.itineraryId;
    if (id == null) {
      // create
      final start = widget.args?.startDate ?? DateTime.now();
      final days = widget.args?.initialDays ?? 3;
      final ref = _col.doc();
      await ref.set({
        'name': widget.args?.initialName ?? 'My Trip',
        'startDate': Timestamp.fromDate(
          DateTime(start.year, start.month, start.day),
        ),
        'endDate': Timestamp.fromDate(
          DateTime(
            start.year,
            start.month,
            start.day,
          ).add(Duration(days: days - 1)),
        ),
        'dayCount': days,
        'totalCost': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _itineraryId = ref.id;
    } else {
      _itineraryId = id;
    }

    final doc = await _col.doc(_itineraryId!).get();
    final data = doc.data()!;
    _nameCtrl.text = (data['name'] ?? 'My Trip').toString();
    _start = ((data['startDate'] as Timestamp).toDate());
    _dayCount = (data['dayCount'] as num?)?.toInt() ?? 3;
    _currentDay = 1;

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _page.dispose();
    super.dispose();
  }

  Future<void> _saveMeta() async {
    if (_itineraryId == null) return;
    final end = DateTime(
      _start.year,
      _start.month,
      _start.day,
    ).add(Duration(days: _dayCount - 1));
    await _col.doc(_itineraryId!).update({
      'name': _nameCtrl.text.trim().isEmpty ? 'My Trip' : _nameCtrl.text.trim(),
      'startDate': Timestamp.fromDate(
        DateTime(_start.year, _start.month, _start.day),
      ),
      'endDate': Timestamp.fromDate(end),
      'dayCount': _dayCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip details saved')));
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _start = d);
  }

  void _goToDay(int day) {
    setState(() => _currentDay = day);
    _page.animateToPage(
      day - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM');
    final end = DateTime(
      _start.year,
      _start.month,
      _start.day,
    ).add(Duration(days: _dayCount - 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Plan your trip'),
        actions: [
          IconButton(
            tooltip: 'Open Google Maps',
            onPressed: () => launchUrl(
              Uri.parse('https://www.google.com/maps'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.directions_outlined),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _saveMeta,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Meta
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Trip name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          onSubmitted: (_) => _saveMeta(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.event_outlined),
                                title: const Text('Start date'),
                                subtitle: Text(df.format(_start)),
                                onTap: _pickStartDate,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_view_day_outlined),
                                  const SizedBox(width: 3),
                                  const Text('Days:'),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 126,
                                    ),
                                    child: _StepperPill(
                                      value: _dayCount,
                                      onMinus: _dayCount > 1
                                          ? () => setState(() => _dayCount--)
                                          : null,
                                      onPlus: () => setState(() => _dayCount++),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dates: ${df.format(_start)} → ${df.format(end)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Day selector (chips synced with PageView)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _dayCount,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final day = i + 1;
                      final date = DateTime(
                        _start.year,
                        _start.month,
                        _start.day,
                      ).add(Duration(days: i));
                      final selected = _currentDay == day;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(
                          'Day $day • ${DateFormat('MMM d').format(date)}',
                        ),
                        onSelected: (_) => _goToDay(day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Day pages
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _currentDay = i + 1),
                    itemCount: _dayCount,
                    itemBuilder: (_, index) {
                      final dayIndex = index + 1;
                      final date = DateTime(
                        _start.year,
                        _start.month,
                        _start.day,
                      ).add(Duration(days: index));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItineraryDayWidget(
                          itineraryId: _itineraryId!,
                          dayIndex: dayIndex,
                          date: date,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: FilledButton.icon(
            onPressed: _saveMeta,
            icon: const Icon(Icons.check),
            label: const Text('Save trip'),
          ),
        ),
      ),
    );
  }
}

class _StepperPill extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _StepperPill({required this.value, this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove), onPressed: onMinus),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: onPlus),
        ],
      ),
    );
  }
}
