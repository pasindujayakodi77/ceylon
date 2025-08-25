import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ceylon/features/business/data/business_analytics_service.dart';

import 'event_editor_screen.dart';

class BusinessEventsScreen extends StatefulWidget {
  const BusinessEventsScreen({super.key});

  @override
  State<BusinessEventsScreen> createState() => _BusinessEventsScreenState();
}

class _BusinessEventsScreenState extends State<BusinessEventsScreen> {
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() => _businessId = snap.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final eventsRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('events')
        .orderBy('startsAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('🎟️ Events & Promotions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text('No events yet. Tap + to add one.'),
            );
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = (doc.data() as Map<String, dynamic>?) ?? {};
              final title = (data['title'] ?? 'Untitled').toString();
              final banner = (data['banner'] ?? '').toString();

              String dateText = '';
              final startTs = data['startsAt'] as Timestamp?;
              final endTs = data['endsAt'] as Timestamp?;
              if (startTs != null && endTs != null) {
                final start = startTs.toDate();
                final end = endTs.toDate();
                dateText =
                    "${start.toLocal().toString().split('.').first} → ${end.toLocal().toString().split('.').first}";
              }

              return Card(
                child: ListTile(
                  leading: banner.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            banner,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  title: Text(title),
                  subtitle: dateText.isNotEmpty ? Text(dateText) : null,
                  onTap: () async {
                    // Record owner viewing the event
                    await BusinessAnalyticsService.instance.recordEvent(
                      _businessId!,
                      'event_view_${doc.id}',
                    );
                    if (!mounted) return;
                    final route = MaterialPageRoute(
                      builder: (_) => EventEditorScreen(
                        businessId: _businessId!,
                        eventId: doc.id,
                        initialData: data,
                      ),
                    );
                    await Navigator.push(context, route);
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text(
                              'Are you sure you want to delete this event?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (!mounted) return;
                        if (ok == true) {
                          await FirebaseFirestore.instance
                              .collection('businesses')
                              .doc(_businessId!)
                              .collection('events')
                              .doc(doc.id)
                              .delete();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Event deleted')),
                          );
                        }
                      } else if (v == 'view_rsvps') {
                        final rsvpsSnap = await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(_businessId!)
                            .collection('events')
                            .doc(doc.id)
                            .collection('rsvps')
                            .get();
                        if (!mounted) return;
                        final rsvps = rsvpsSnap.docs;
                        if (!mounted) return;
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Attendees (${rsvps.length})',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 300,
                                  child: ListView.separated(
                                    itemCount: rsvps.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (ctx2, idx) {
                                      final r =
                                          (rsvps[idx].data()
                                              as Map<String, dynamic>?) ??
                                          {};
                                      final name = (r['name'] ?? 'Guest')
                                          .toString();
                                      final email = (r['email'] ?? '')
                                          .toString();
                                      final attended =
                                          (r['attended'] as bool?) ?? false;
                                      return ListTile(
                                        title: Text(name),
                                        subtitle: Text(email),
                                        trailing: attended
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              )
                                            : TextButton(
                                                child: const Text(
                                                  'Mark attended',
                                                ),
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('businesses')
                                                      .doc(_businessId!)
                                                      .collection('events')
                                                      .doc(doc.id)
                                                      .collection('rsvps')
                                                      .doc(rsvps[idx].id)
                                                      .update({
                                                        'attended': true,
                                                      });
                                                  await BusinessAnalyticsService
                                                      .instance
                                                      .recordEvent(
                                                        _businessId!,
                                                        'event_attended_${doc.id}',
                                                      );
                                                  if (!mounted) return;
                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (v == 'export') {
                        final rsvpsSnap = await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(_businessId!)
                            .collection('events')
                            .doc(doc.id)
                            .collection('rsvps')
                            .get();
                        final rows = <String>[];
                        rows.add('name,email,phone,attended');
                        for (final r in rsvpsSnap.docs) {
                          final d = (r.data() as Map<String, dynamic>?) ?? {};
                          rows.add(
                            '"${d['name'] ?? ''}","${d['email'] ?? ''}","${d['phone'] ?? ''}","${(d['attended'] ?? false)}"',
                          );
                        }
                        final csv = rows.join('\n');
                        await Clipboard.setData(ClipboardData(text: csv));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendees CSV copied to clipboard'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'view_rsvps',
                        child: Text('View RSVPs'),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Text('Export attendees'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete event'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        onPressed: () async {
          final route = MaterialPageRoute(
            builder: (_) => EventEditorScreen(businessId: _businessId!),
          );
          await Navigator.push(context, route);
        },
      ),
    );
  }
}
