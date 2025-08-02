import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('onboarding_seen') ?? false;
  runApp(CeylonApp(seenOnboarding: seen));
}

class CeylonApp extends StatelessWidget {
  final bool seenOnboarding;
  const CeylonApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEYLON',
      debugShowCheckedModeBanner: false,
      home: seenOnboarding ? const LoginScreen() : const OnboardingScreen(),
    );
  }
}
