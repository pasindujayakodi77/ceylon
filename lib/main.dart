import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;

  final authRepo = AuthRepository();
  final isSignedIn = FirebaseAuth.instance.currentUser != null;

  runApp(
    BlocProvider(
      create: (_) => AuthBloc(authRepo: authRepo),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: seenOnboarding
            ? (isSignedIn ? const HomeScreen() : const LoginScreen())
            : const OnboardingScreen(),
      ),
    ),
  );
}
