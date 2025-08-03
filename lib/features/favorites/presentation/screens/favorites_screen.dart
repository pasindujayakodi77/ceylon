import 'package:ceylon/features/favorites/presentation/screens/bookmarks_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ceylon/generated/app_localizations.dart';
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.favorites)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
              child: const Text("📂 View Bookmarked Trips & Attractions"),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noFavoritesYet),
                  );

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
          ),
        ],
      ),
    );
  }
}
