// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

class BusinessReviewsScreen extends StatefulWidget {
  final String businessId;
  const BusinessReviewsScreen({super.key, required this.businessId});

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  final _repo = BusinessRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
  final _controller = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Review>>(
              stream: _repo.streamReviews(widget.businessId, pageSize: 20),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final items = snap.data ?? [];
                if (items.isEmpty)
                  return const Center(
                    child: Text('No reviews yet. Be the first!'),
                  );
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return ListTile(
                      title: Text('★' * r.rating),
                      subtitle: Text(r.text),
                      trailing: Text(
                        r.createdAt
                            .toDate()
                            .toLocal()
                            .toString()
                            .split('.')
                            .first,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: _rating,
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}★'),
                    ),
                  ),
                  onChanged: (v) => setState(() => _rating = v ?? 5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a review...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await _repo.submitReview(
                        widget.businessId,
                        text: text,
                        rating: _rating,
                      );
                      _controller.clear();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review submitted')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
