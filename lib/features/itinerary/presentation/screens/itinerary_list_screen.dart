// FILE: lib/features/itinerary/presentation/screens/itinerary_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../routes/itinerary_routes.dart';

class ItineraryListScreen extends StatefulWidget {
  const ItineraryListScreen({super.key});

  @override
  State<ItineraryListScreen> createState() => _ItineraryListScreenState();
}

class _ItineraryListScreenState extends State<ItineraryListScreen> {
  String _query = '';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('itineraries');

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() =>
      _col.orderBy('startDate', descending: true).snapshots();

  Future<void> _createQuick() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 2));
    final ref = _col.doc();
    await ref.set({
      'name': 'My Trip',
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'dayCount': 3,
      'totalCost': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      ItineraryRoutes.builder,
      arguments: ItineraryBuilderArgs(itineraryId: ref.id),
    );
  }

  Future<void> _deleteCascade(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete itinerary?'),
        content: const Text(
          'This will remove the itinerary and all its items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final items = await _col.doc(id).collection('items').get();
    for (final d in items.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_col.doc(id));
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Itinerary deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d');
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗓️ My Itineraries'),
        actions: [
          IconButton(
            tooltip: 'New itinerary',
            icon: const Icon(Icons.add),
            onPressed: _createQuick,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final list = docs.where((d) {
            final name = (d['name'] ?? '').toString().toLowerCase();
            return _query.isEmpty || name.contains(_query);
          }).toList();

          if (list.isEmpty) {
            return const _Empty();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = list[i];
              final id = d.id;
              final name = (d['name'] ?? 'Untitled').toString();
              final start = (d['startDate'] as Timestamp?)?.toDate();
              final end = (d['endDate'] as Timestamp?)?.toDate();
              final dayCount = (d['dayCount'] as num?)?.toInt() ?? 0;
              final total = (d['totalCost'] as num?)?.toDouble() ?? 0.0;

              return Card(
                child: ListTile(
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    start != null && end != null
                        ? '${df.format(start)} → ${df.format(end)}  •  $dayCount days'
                        : '$dayCount days',
                  ),
                  leading: CircleAvatar(child: Text(dayCount.toString())),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (total > 0)
                        Chip(label: Text('LKR ${total.toStringAsFixed(0)}')),
                      IconButton(
                        tooltip: 'View',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          ItineraryRoutes.view,
                          arguments: ItineraryViewArgs(id),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          ItineraryRoutes.builder,
                          arguments: ItineraryBuilderArgs(itineraryId: id),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteCascade(id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_takeoff, size: 64, color: Colors.black38),
            const SizedBox(height: 8),
            Text(
              'No itineraries yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to create your first trip.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
