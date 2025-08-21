import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerificationInboxScreen extends StatelessWidget {
  const VerificationInboxScreen({super.key});

  Future<void> _decide({
    required String requestId,
    required String businessId,
    required bool approve,
  }) async {
    final db = FirebaseFirestore.instance;
    final now = FieldValue.serverTimestamp();
    await db.runTransaction((tx) async {
      final reqRef = db.collection('verification_requests').doc(requestId);
      tx.update(reqRef, {
        'status': approve ? 'approved' : 'rejected',
        'decidedAt': now,
        // 'decidedBy': <set current admin uid if you have it on client>,
      });
      if (approve) {
        final bizRef = db.collection('businesses').doc(businessId);
        tx.update(bizRef, {
          'verified': true,
          'verifiedAt': now,
          // 'verifiedBy': <admin uid>,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('verification_requests')
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
              final businessId = (m['businessId'] ?? '').toString();
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
                            TextButton(
                              onPressed: () => _decide(
                                requestId: d.id,
                                businessId: businessId,
                                approve: false,
                              ),
                              child: const Text('Reject'),
                            ),
                            ElevatedButton(
                              onPressed: () => _decide(
                                requestId: d.id,
                                businessId: businessId,
                                approve: true,
                              ),
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
