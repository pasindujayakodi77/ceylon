import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    if (snap.docs.isNotEmpty) {
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final desc = data['description'] ?? '';
              final banner = data['banner'] ?? '';
              final published = (data['published'] as bool?) ?? false;

              final DateTime? start = (data['startsAt'] as Timestamp?)
                  ?.toDate();
              final DateTime? end = (data['endsAt'] as Timestamp?)?.toDate();

              String dateText = '';
              if (start != null && end != null) {
                dateText =
                    "${start.toLocal().toString().split('.').first} → ${end.toLocal().toString().split('.').first}";
              }

              return Card(
                child: ListTile(
                  leading: banner.toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            banner,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.event, size: 40),
                  title: Row(
                    children: [
                      Expanded(child: Text(title)),
                      if (published)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: Text('Published'),
                            backgroundColor: Colors.greenAccent,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: Text('Draft'),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateText.isNotEmpty)
                        Text(dateText, style: const TextStyle(fontSize: 12)),
                      if (desc.toString().isNotEmpty)
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  onTap: () async {
                    // Open editor in edit mode
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventEditorScreen(
                          businessId: _businessId!,
                          eventId: doc.id,
                          initialData: data,
                        ),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
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
                      if (ok == true) {
                        await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(_businessId)
                            .collection('events')
                            .doc(doc.id)
                            .delete();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Event deleted')),
                          );
                        }
                      }
                    },
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventEditorScreen(businessId: _businessId!),
            ),
          );
        },
      ),
    );
  }
}
