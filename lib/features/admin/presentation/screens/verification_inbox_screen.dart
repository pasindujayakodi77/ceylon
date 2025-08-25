import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/admin_config.dart';

class VerificationInboxScreen extends StatefulWidget {
  const VerificationInboxScreen({super.key});

  @override
  State<VerificationInboxScreen> createState() =>
      _VerificationInboxScreenState();
}

class _VerificationInboxScreenState extends State<VerificationInboxScreen> {
  String _functionsBase = '';
  final Map<String, String> _localStatus = {}; // reqId -> 'approved'|'rejected'
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadFunctionsBase();
  }

  Future<void> _loadFunctionsBase() async {
    final base = await AdminConfig.functionsBaseUrl();
    if (!mounted) return;
    setState(() => _functionsBase = base);
  }

  String _businessIdFromRef(DocumentReference ref) {
    // path like: businesses/{businessId}/verification_requests/{reqId}
    final parts = ref.path.split('/');
    final idx = parts.indexOf('businesses');
    if (idx >= 0 && parts.length > idx + 1) return parts[idx + 1];
    return '';
  }

  Future<String> _fetchAdminIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Empty token');
    return token;
  }

  Future<bool> _confirm(String title, String body) async {
    if (!mounted) return false;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _handleDecision(
    QueryDocumentSnapshot d,
    String businessId,
    bool approve,
  ) async {
    final reqId = d.id;
    final messenger = ScaffoldMessenger.of(context);

    final action = approve ? 'Approve' : 'Reject';
    final confirmed = await _confirm(
      '$action request',
      'Are you sure you want to $action this verification request for $businessId?',
    );
    if (!confirmed) return;

    // optimistic update
    setState(() {
      _localStatus[reqId] = approve ? 'approved' : 'rejected';
      _processing.add(reqId);
    });

    try {
      final idToken = await _fetchAdminIdToken();
      await _decideHttp(
        requestId: reqId,
        businessId: businessId,
        approve: approve,
        idToken: idToken,
      );
      // success — let Firestore stream drive the final state
      messenger.showSnackBar(SnackBar(content: Text('$action successful')));
    } catch (e) {
      // revert optimistic change
      if (mounted) {
        setState(() {
          _localStatus.remove(reqId);
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('$action failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing.remove(reqId);
        });
      }
    }
  }

  // Use the admin HTTP endpoint to decide. The endpoint requires an ID token
  // with admin claim in Authorization: Bearer <idToken>.
  Future<void> _decideHttp({
    required String requestId,
    required String businessId,
    required bool approve,
    required String idToken,
    String? note,
  }) async {
    final base = _functionsBase.isNotEmpty
        ? _functionsBase
        : await AdminConfig.functionsBaseUrl();
    if (base.isEmpty)
      throw Exception('Admin functions base URL not configured');

    final url = Uri.parse('$base/adminApproveVerification');
    final body = jsonEncode({
      'businessId': businessId,
      'reqId': requestId,
      'approve': approve,
      if (note != null) 'note': note,
    });

    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Admin API error: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Query across all nested verification_requests under businesses/*
    final q = FirebaseFirestore.instance
        .collectionGroup('verification_requests')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('🛡 Verification Inbox')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No requests'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              final m = d.data();
              final status = (m['status'] ?? 'pending').toString();
              // Some requests include businessId field; otherwise infer from ref path
              final businessId =
                  (m['businessId'] ?? _businessIdFromRef(d.reference))
                      .toString();
              final note = (m['note'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: Icon(
                    status == 'approved'
                        ? Icons.verified
                        : status == 'rejected'
                        ? Icons.block
                        : Icons.hourglass_empty,
                    color: status == 'approved'
                        ? Colors.blue
                        : status == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text('Business: $businessId'),
                  subtitle: Text(
                    'Status: $status\nNote: ${note.isEmpty ? '—' : note}',
                  ),
                  isThreeLine: true,
                  trailing: status == 'pending'
                      ? Wrap(
                          spacing: 8,
                          children: [
                            _processing.contains(d.id)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () =>
                                        _handleDecision(d, businessId, false),
                                    child: const Text('Reject'),
                                  ),
                            _processing.contains(d.id)
                                ? const SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: () =>
                                        _handleDecision(d, businessId, true),
                                    child: const Text('Approve'),
                                  ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
