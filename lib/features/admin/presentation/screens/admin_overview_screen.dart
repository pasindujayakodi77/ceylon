import 'package:flutter/material.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.inbox),
              label: const Text('Verification requests'),
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin/verification-requests'),
            ),
            const SizedBox(height: 12),
            // Add other admin tools here
          ],
        ),
      ),
    );
  }
}
