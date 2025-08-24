// FILE: lib/features/itinerary/presentation/widgets/itinerary_day_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'itinerary_item_widget.dart';
import '../../data/itinerary_adapter.dart' as adapter;
import 'package:ceylon/features/attractions/data/attraction_repository.dart';
import 'package:ceylon/features/attractions/data/attraction_model.dart';

class ItineraryDayWidget extends StatefulWidget {
  final String itineraryId;
  final int dayIndex;
  final DateTime date;
  final bool readOnly;

  const ItineraryDayWidget({
    super.key,
    required this.itineraryId,
    required this.dayIndex,
    required this.date,
    this.readOnly = false,
  });

  @override
  State<ItineraryDayWidget> createState() => _ItineraryDayWidgetState();
}

class _ItineraryDayWidgetState extends State<ItineraryDayWidget> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _itemsCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('itineraries')
      .doc(widget.itineraryId)
      .collection('items');

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() => _itemsCol
      .where('dayIndex', isEqualTo: widget.dayIndex)
      .orderBy('order')
      .snapshots();

  Future<void> _addOrEditSheet({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final isEdit = doc != null;
    final m = doc?.data() ?? {};
    final titleCtrl = TextEditingController(
      text: (m['title'] ?? '').toString(),
    );
    final noteCtrl = TextEditingController(text: (m['note'] ?? '').toString());
    final pickedAttractionId = ValueNotifier<String?>(
      m['attractionId']?.toString(),
    );
    final pickedImageUrl = ValueNotifier<String?>(m['imageUrl']?.toString());
    final type = ValueNotifier<String>(
      (m['type'] ?? 'place').toString(),
    ); // place | food | transport | stay | activity
    final startTime = ValueNotifier<String>(
      (m['startTime'] ?? '09:00').toString(),
    );
    final duration = ValueNotifier<int>(
      (m['durationMins'] as num?)?.toInt() ?? 60,
    );
    final cost = ValueNotifier<double>((m['cost'] as num?)?.toDouble() ?? 0.0);
    // lat/lng removed: no controllers

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      // Open attraction picker
                      final repo = AttractionRepository();
                      final list = await repo.getAttractions();
                      final searchCtrl = TextEditingController();
                      final selected = await showDialog<Attraction>(
                        context: context,
                        builder: (c) => StatefulBuilder(
                          builder: (c2, setState) {
                            List<Attraction> filtered() {
                              final q = searchCtrl.text.trim().toLowerCase();
                              if (q.isEmpty) return list;
                              return list.where((a) {
                                final name = a.name.toLowerCase();
                                final loc = a.location.toLowerCase();
                                return name.contains(q) || loc.contains(q);
                              }).toList();
                            }

                            return SimpleDialog(
                              title: const Text('Pick attraction'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: TextField(
                                    controller: searchCtrl,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.search),
                                      hintText: 'Search attractions',
                                      suffixIcon: searchCtrl.text.isEmpty
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                searchCtrl.clear();
                                                setState(() {});
                                              },
                                            ),
                                    ),
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ),
                                SizedBox(
                                  width: double.maxFinite,
                                  height: 400,
                                  child: Builder(
                                    builder: (ctx) {
                                      final items = filtered();
                                      return items.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.all(24.0),
                                              child: Center(
                                                child: Text(
                                                  'No attractions found',
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: items.length,
                                              itemBuilder: (ctx, i) {
                                                final a = items[i];
                                                return ListTile(
                                                  leading: a.imageUrl != null
                                                      ? Image.network(
                                                          a.imageUrl!,
                                                          width: 56,
                                                          height: 56,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const SizedBox(
                                                          width: 56,
                                                          height: 56,
                                                        ),
                                                  title: Text(a.name),
                                                  subtitle: Text(a.location),
                                                  onTap: () =>
                                                      Navigator.pop(ctx, a),
                                                );
                                              },
                                            );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );

                      if (selected != null) {
                        titleCtrl.text = selected.name;
                        noteCtrl.text = selected.description;
                        pickedAttractionId.value = selected.id;
                        pickedImageUrl.value = selected.imageUrl;
                      }
                    },
                    icon: const Icon(Icons.place),
                    label: const Text('Pick attraction'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<String?>(
                      valueListenable: pickedAttractionId,
                      builder: (ctx, val, _) =>
                          Text(val == null ? '' : 'Selected: $val'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isEdit ? 'Edit item' : 'Add item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in [
                    'place',
                    'food',
                    'transport',
                    'stay',
                    'activity',
                  ])
                    ChoiceChip(
                      label: Text(t),
                      selected: type.value == t,
                      onSelected: (_) => type.value = t,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              // latitude/longitude inputs removed
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Start time'),
                      subtitle: Text(startTime.value),
                      onTap: () async {
                        final parts = startTime.value.split(':');
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.parse(parts[0]),
                            minute: int.parse(parts[1]),
                          ),
                        );
                        if (t != null) {
                          startTime.value =
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Duration'),
                      subtitle: Text('${duration.value} mins'),
                      onTap: () async {
                        final v = await showDialog<int>(
                          context: context,
                          builder: (c) => SimpleDialog(
                            title: const Text('Duration (mins)'),
                            children: [
                              for (final m in [30, 45, 60, 90, 120, 180])
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(c, m),
                                  child: Text('$m'),
                                ),
                            ],
                          ),
                        );
                        if (v != null) duration.value = v;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Estimated cost'),
                      subtitle: Text(cost.value.toStringAsFixed(0)),
                      onTap: () async {
                        final c = await showDialog<double>(
                          context: context,
                          builder: (ctx) {
                            final ctrl = TextEditingController(
                              text: cost.value.toStringAsFixed(0),
                            );
                            return AlertDialog(
                              title: const Text('Cost (LKR)'),
                              content: TextField(
                                controller: ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  prefixText: 'LKR ',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(
                                    ctx,
                                    double.tryParse(ctrl.text) ?? 0,
                                  ),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        if (c != null) cost.value = c;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final map = {
                        'dayIndex': widget.dayIndex,
                        'type': type.value,
                        'title': titleCtrl.text.trim(),
                        'note': noteCtrl.text.trim(),
                        'startTime': startTime.value,
                        'durationMins': duration.value,
                        'cost': cost.value,
                        // lat/lng removed
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (isEdit) {
                        await doc.reference.update(map);
                      } else {
                        final last = await _itemsCol
                            .where('dayIndex', isEqualTo: widget.dayIndex)
                            .orderBy('order', descending: true)
                            .limit(1)
                            .get();
                        final next = last.docs.isEmpty
                            ? 0
                            : (((last.docs.first['order'] as num?)?.toInt()) ??
                                      0) +
                                  1;
                        await _itemsCol.add({
                          ...map,
                          'order': next,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Save' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reorder(
    List<DocumentSnapshot<Map<String, dynamic>>> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < items.length; i++) {
      batch.update(items[i].reference, {'order': i});
    }
    await batch.commit();
  }

  double _sumCost(QuerySnapshot<Map<String, dynamic>> snap) {
    double t = 0;
    for (final d in snap.docs) {
      final c = (d['cost'] as num?)?.toDouble() ?? 0;
      t += c;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!.docs;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.today_outlined),
                title: Text('Day ${widget.dayIndex}'),
                subtitle: Text(df.format(widget.date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        'LKR ${_sumCost(snap.data!).toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.readOnly)
                      IconButton(
                        tooltip: 'Add item',
                        onPressed: () => _addOrEditSheet(),
                        icon: const Icon(Icons.add),
                      ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: items.isEmpty
                    ? const _EmptyDay()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                        buildDefaultDragHandles: false,
                        itemCount: items.length,
                        onReorder: (o, n) {
                          if (widget.readOnly) return;
                          _reorder(List.of(items), o, n);
                        },
                        itemBuilder: (_, i) {
                          final d = items[i];
                          final type = (d['type'] ?? 'place').toString();
                          final title = (d['title'] ?? '').toString();
                          final note = (d['note'] ?? '').toString();
                          final mins =
                              (d['durationMins'] as num?)?.toInt() ?? 0;
                          final cost = (d['cost'] as num?)?.toDouble() ?? 0.0;
                          // lat/lng removed from storage

                          final item = adapter.ItineraryItem(
                            id: d.id,
                            title: title,
                            startTime:
                                DateTime.now(), // placeholder, adapter uses TimeOfDay in some places
                            durationMinutes: mins,
                            note: note.isEmpty ? null : note,
                            // latitude/longitude removed
                            cost: cost == 0.0 ? null : cost,
                            type: (() {
                              switch (type) {
                                case 'place':
                                case 'activity':
                                  return adapter.ItineraryItemType.activity;
                                case 'food':
                                  return adapter.ItineraryItemType.meal;
                                case 'transport':
                                  return adapter
                                      .ItineraryItemType
                                      .transportation;
                                case 'stay':
                                  return adapter
                                      .ItineraryItemType
                                      .accommodation;
                                default:
                                  return adapter.ItineraryItemType.other;
                              }
                            })(),
                          );

                          return Dismissible(
                            key: ValueKey(d.id),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Icon(Icons.delete_outline),
                                ),
                              ),
                            ),
                            direction: widget.readOnly
                                ? DismissDirection.none
                                : DismissDirection.startToEnd,
                            confirmDismiss: (_) async {
                              if (widget.readOnly) return false;
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Remove item?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton.tonal(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) => d.reference.delete(),
                            child: ItineraryItemWidget(
                              item: item,
                              onTap: () {
                                // open directions when tapping the item
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(title)}',
                                );
                                launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              onEdit: widget.readOnly
                                  ? null
                                  : () => _addOrEditSheet(doc: d),
                              onDelete: widget.readOnly
                                  ? null
                                  : () => d.reference.delete(),
                              isLast: i == items.length - 1,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 56,
                  color: Colors.black38,
                ),
                const SizedBox(height: 6),
                Text(
                  'Nothing planned yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to add places, food, transport, stays or activities.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
