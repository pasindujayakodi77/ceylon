import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/dev/seed_firestore.dart';

class DevToolsScreen extends StatelessWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Dev Tools are debug‑only')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('🧰 Dev Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () async {
              await FirestoreSeeder.seedAttractions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seeded attractions')),
                );
              }
            },
            child: const Text('Seed attractions (10)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await FirestoreSeeder.seedTripTemplates();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seeded trip templates')),
                );
              }
            },
            child: const Text('Seed trip templates (2)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await FirestoreSeeder.seedMyBusinessIfMissing();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ensured my business')),
                );
              }
            },
            child: const Text('Ensure my business doc'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async {
              await FirestoreSeeder.seedAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All seeding done')),
                );
              }
            },
            child: const Text('Run ALL'),
          ),
        ],
      ),
    );
  }
}
