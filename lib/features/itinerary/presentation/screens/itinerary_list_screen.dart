import 'package:ceylon/features/itinerary/presentation/screens/itinerary_builder_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItineraryListScreen extends StatelessWidget {
  const ItineraryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .orderBy('created_at', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("📅 My Itineraries")),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No trips yet"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'];
              final days = List<String>.from(data['days']);
              return Card(
                child: ListTile(
                  title: Text(title ?? "Untitled"),
                  subtitle: Text("${days.length} day(s)"),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ItineraryBuilderScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
