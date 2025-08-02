import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('saved_at', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("❤️ My Favorites")),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("No favorites yet"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Image.network(
                    data['photo'],
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(data['name']),
                  subtitle: Text(data['desc']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
