import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💼 Business Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(child: Text("Welcome, business user 👋")),
    );
  }
}
