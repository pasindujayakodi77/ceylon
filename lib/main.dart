import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:ceylon/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
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

  await FCMService.init();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
  final isSignedIn = FirebaseAuth.instance.currentUser != null;

  final authRepo = AuthRepository();

  runApp(
    BlocProvider(
      create: (_) => AuthBloc(authRepo: authRepo),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {'/home': (_) => const TouristHomeScreen()},
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('dv'),
          Locale('ru'),
          Locale('de'),
          Locale('fr'),
          Locale('nl'),
        ],
        locale: Locale('en'), // Default
        home: seenOnboarding
            ? (isSignedIn ? const RoleRouter() : const LoginScreen())
            : const OnboardingScreen(),
      ),
    ),
  );
}
