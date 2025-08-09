import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ceylon/features/holidays/data/local_holidays_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ceylon/features/itinerary/data/itinerary_service.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  final _repo = LocalHolidaysRepository();
  final _searchCtrl = TextEditingController();

  String _country = 'LK';
  late int _year;
  late int _month;
  bool _loading = true;

  Future<void> _addHolidayToItinerary({
    required String countryCode,
    required String holidayName,
    required DateTime date,
  }) async {
    // Must be signed in
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add to itinerary')),
      );
      return;
    }

    final svc = ItineraryService.instance;
    final existing = await svc.listItineraries();

    final nameCtrl = TextEditingController();
    String? chosenId = existing.isNotEmpty
        ? existing.first['id'] as String
        : null;
    String? note;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add to Itinerary',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Holiday: $holidayName'),
              Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(date)}'),
              const SizedBox(height: 12),

              if (existing.isNotEmpty) ...[
                const Text('Choose existing itinerary'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: chosenId,
                  items: [
                    for (final it in existing)
                      DropdownMenuItem<String>(
                        value: it['id'] as String,
                        child: Text(
                          (it['name'] ?? 'Trip') as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => chosenId = v,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text('…or create a new itinerary'),
              ] else ...[
                const Text('Create a new itinerary'),
              ],
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'New itinerary name',
                  hintText: 'e.g., Sri Lanka April Trip',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => note = v,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Why this matters to your plan?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Pick existing OR create new
                        String itineraryId;
                        if (chosenId == null) {
                          itineraryId = await svc.createItinerary(
                            nameCtrl.text.trim().isEmpty
                                ? 'My Trip'
                                : nameCtrl.text.trim(),
                          );
                        } else {
                          itineraryId = chosenId!;
                        }

                        await svc.addHolidayItem(
                          itineraryId: itineraryId,
                          date: date,
                          countryCode: countryCode,
                          holidayName: holidayName,
                          note: note,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Added to itinerary'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    nameCtrl.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _init();
  }

  Future<void> _init() async {
    await _repo.load();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pickMonthYear() async {
    // Simple month/year pick via DatePicker (user picks any day in target month)
    final initial = DateTime(_year, _month, 1);
    final first = DateTime(_year - 1, 1, 1);
    final last = DateTime(_year + 2, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select any date in the target month',
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
    }
  }

  Color _typeColor(String type) {
    final hex = (_repo.typeInfo(type)?['color'] as String?) ?? '#90A4AE';
    // parse #RRGGBB
    final v = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 | v).withOpacity(1);
  }

  String _typeLabel(String type) {
    return (_repo.typeInfo(type)?['label'] as String?) ?? type;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final codes = _repo.countryCodes;
    final holidays = _repo.filter(
      _country,
      _year,
      _month,
      search: _searchCtrl.text,
    );
    final monthText = DateFormat.yMMMM().format(DateTime(_year, _month, 1));
    final upNext = _repo.upcoming(_country, take: 3);

    return Scaffold(
      appBar: AppBar(title: const Text('🗓 Public Holiday Calendar')),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                        items: codes.map((c) {
                          final name = _repo.byCode(c)?.name ?? c;
                          return DropdownMenuItem(
                            value: c,
                            child: Text('$name ($c)'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _country = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(monthText),
                        onPressed: _pickMonthYear,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search holiday',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // Upcoming glance
          if (upNext.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: upNext.map((h) {
                    final d = DateFormat('MMM d').format(h.date);
                    return Chip(
                      label: Text('$d • ${h.name}'),
                      backgroundColor: _typeColor(h.type).withOpacity(0.10),
                      side: BorderSide(
                        color: _typeColor(h.type).withOpacity(0.30),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Results list
          Expanded(
            child: holidays.isEmpty
                ? const Center(child: Text('No holidays this month.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: holidays.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final h = holidays[i];
                      final dd = DateFormat('EEE, MMM d, yyyy').format(h.date);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _typeColor(h.type).withOpacity(0.15),
                          child: Text(
                            DateFormat('d').format(h.date),
                            style: TextStyle(color: _typeColor(h.type)),
                          ),
                        ),
                        title: Text(h.name),
                        subtitle: Text(dd),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _typeColor(h.type).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _typeColor(h.type).withOpacity(0.30),
                                ),
                              ),
                              child: Text(
                                _typeLabel(h.type),
                                style: TextStyle(
                                  color: _typeColor(h.type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Add to itinerary',
                              icon: const Icon(Icons.playlist_add),
                              onPressed: () {
                                _addHolidayToItinerary(
                                  countryCode: _country,
                                  holidayName: h.name,
                                  date: h.date,
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // Also allow tapping the row to add
                          _addHolidayToItinerary(
                            countryCode: _country,
                            holidayName: h.name,
                            date: h.date,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
