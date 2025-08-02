import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final itinerariesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .orderBy('created_at', descending: true);

    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('saved_at', descending: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📂 Bookmarked Items"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Itineraries"),
              Tab(icon: Icon(Icons.favorite), text: "Favorites"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ItineraryList(ref: itinerariesRef),
            _FavoritesList(ref: favoritesRef),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final Query ref;
  const _FavoritesList({required this.ref});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No favorites saved"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: Image.network(data['photo'], width: 60),
              title: Text(data['name']),
              subtitle: Text(data['desc']),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ItineraryList extends StatelessWidget {
  final Query ref;
  const _ItineraryList({required this.ref});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No itineraries saved"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['title'] ?? "Untitled"),
              subtitle: Text("\${(data['days'] as List).length} day(s)"),
            );
          }).toList(),
        );
      },
    );
  }
}
