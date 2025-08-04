import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('my_reviews')
        .orderBy('updated_at', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("✏️ My Reviews")),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No reviews yet"));

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final photoUrl = data['photo'] as String? ?? '';
              final place = data['place'] as String? ?? 'Unknown Place';
              final comment = data['comment'] as String? ?? '';
              final rating = (data['rating'] is int)
                  ? (data['rating'] as int).toDouble()
                  : (data['rating'] as double?) ?? 0.0;

              return ListTile(
                key: ValueKey(doc.id),
                leading: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        width: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 60),
                      )
                    : const Icon(Icons.image_not_supported, size: 60),
                title: Text(place),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBarIndicator(
                      rating: rating,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemSize: 18.0,
                    ),
                    Text(comment),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
