// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'event_editor_screen.dart';

class BusinessEventsScreen extends StatefulWidget {
  final String businessId;
  const BusinessEventsScreen({super.key, required this.businessId});

  @override
  State<BusinessEventsScreen> createState() => _BusinessEventsScreenState();
}

class _BusinessEventsScreenState extends State<BusinessEventsScreen> {
  final _repo = BusinessRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
  List<BusinessEvent> _events = [];
  bool _loading = true;
  String? _error;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ref = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('events')
          .orderBy('startAt', descending: true)
          .limit(20);
      final snap = await ref.get();
      _events = snap.docs.map(BusinessEvent.fromDoc).toList();
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      var q = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('events')
          .orderBy('startAt', descending: true)
          .limit(20);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
      final snap = await q.get();
      _events.addAll(snap.docs.map(BusinessEvent.fromDoc));
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      _hasMore = snap.docs.length == 20;
    } catch (e) {
      // ignore for now
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(businessId: widget.businessId),
      ),
    );
    if (created == true) _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(body: Center(child: Text('Error: $_error')));
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _events.length + 1,
        itemBuilder: (context, i) {
          if (i == _events.length) {
            if (_hasMore) {
              _loadMore();
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 60);
          }
          final e = _events[i];
          return ListTile(
            title: Text(e.title),
            subtitle: Text(e.startAt.toDate().toLocal().toString()),
            trailing: e.published
                ? const Icon(Icons.visibility)
                : const Icon(Icons.visibility_off),
            onTap: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventEditorScreen(
                    businessId: widget.businessId,
                    event: e,
                  ),
                ),
              );
              if (updated == true) _loadInitial();
            },
          );
        },
      ),
    );
  }
}
