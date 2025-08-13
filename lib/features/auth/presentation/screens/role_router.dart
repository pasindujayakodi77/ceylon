import 'package:ceylon/features/business/presentation/screens/business_home_screen.dart';
import 'package:ceylon/features/home/presentation/screens/home_screen_new.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'tourist';

        if (role == 'business') {
          return const BusinessHomeScreen();
        } else {
          return const TouristHomeScreen();
        }
      },
    );
  }
}
