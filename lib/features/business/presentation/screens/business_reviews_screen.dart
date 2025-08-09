import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BusinessReviewsScreen extends StatefulWidget {
  const BusinessReviewsScreen({super.key});

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
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

    final reviewsRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('reviews')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('💬 Reviews & Replies')),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0;
              final comment = (data['comment'] ?? '').toString();
              final author = (data['name'] ?? 'Anonymous').toString();
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              final reply = (data['ownerReply'] as Map<String, dynamic>?) ?? {};

              final replied = reply.isNotEmpty;
              final replyText = (reply['text'] ?? '').toString();
              final replyAt = (reply['repliedAt'] as Timestamp?)?.toDate();

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Review header
                      Row(
                        children: [
                          _Stars(rating: rating),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ts != null)
                            Text(
                              _short(ts),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(comment),

                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      // Owner reply section
                      if (replied) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.reply,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyText,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  if (replyAt != null)
                                    Text(
                                      'Replied • ${_short(replyAt)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        onPressed: () => _openReplyEditor(
                                          doc.id,
                                          initialText: replyText,
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                        label: const Text('Delete'),
                                        onPressed: () => _deleteReply(doc.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply'),
                            onPressed: () => _openReplyEditor(doc.id),
                          ),
                        ),
                      ],
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

  Future<void> _openReplyEditor(String reviewId, {String? initialText}) async {
    final controller = TextEditingController(text: initialText ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                initialText == null ? 'Write a reply' : 'Edit reply',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Say thanks, clarify issues, or offer help…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      // read business
                      final bizSnap = await FirebaseFirestore.instance
                          .collection('businesses')
                          .where('ownerId', isEqualTo: uid)
                          .limit(1)
                          .get();
                      if (bizSnap.docs.isEmpty) return;
                      final bizId = bizSnap.docs.first.id;
                      final bizName =
                          (bizSnap.docs.first.data()['name'] ?? 'Owner')
                              .toString();

                      await FirebaseFirestore.instance
                          .collection('businesses')
                          .doc(bizId)
                          .collection('reviews')
                          .doc(reviewId)
                          .update({
                            'ownerReply': {
                              'text': text,
                              'authorId': uid,
                              'authorName': bizName,
                              'repliedAt': FieldValue.serverTimestamp(),
                            },
                          });

                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Reply saved')));
    }
  }

  Future<void> _deleteReply(String reviewId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Remove your reply to this review?'),
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
    if (ok != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bizSnap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (bizSnap.docs.isEmpty) return;
    final bizId = bizSnap.docs.first.id;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(bizId)
        .collection('reviews')
        .doc(reviewId)
        .update({'ownerReply': FieldValue.delete()});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🗑 Reply deleted')));
    }
  }
}

/* ------ small UI helpers ------ */

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    // Simple star row without extra deps
    final full = rating.floor();
    final half = (rating - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;

    final icons = <Widget>[
      for (var i = 0; i < full; i++)
        const Icon(Icons.star, color: Colors.amber, size: 18),
      for (var i = 0; i < half; i++)
        const Icon(Icons.star_half, color: Colors.amber, size: 18),
      for (var i = 0; i < empty; i++)
        const Icon(Icons.star_border, color: Colors.amber, size: 18),
    ];

    return Row(children: icons);
  }
}

String _short(DateTime d) {
  // e.g., 2025-08-09 14:05
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
