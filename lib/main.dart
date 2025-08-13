import 'package:ceylon/core/navigation/app_router.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:ceylon/features/home/presentation/screens/home_screen_new.dart';
import 'package:ceylon/features/itinerary/data/itinerary_repository.dart';
import 'package:ceylon/services/favorites_provider.dart';
import 'package:ceylon/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService.init();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
  final isSignedIn = FirebaseAuth.instance.currentUser != null;
  final authRepo = AuthRepository();

  // Initialize theme mode from shared preferences
  final savedThemeMode = prefs.getString('theme_mode');
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedThemeMode == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedThemeMode == 'light') {
    initialThemeMode = ThemeMode.light;
  }
  final themeManager = ThemeManager();
  themeManager.setThemeMode(initialThemeMode);

  Widget homeWidget = seenOnboarding
      ? (isSignedIn ? const RoleRouter() : const LoginScreen())
      : const OnboardingScreen();

  runApp(
    MultiProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepo: authRepo)),
        ChangeNotifierProvider.value(value: themeManager),
        Provider<ItineraryRepository>(create: (_) => ItineraryRepository()),
      ],
      child: FavoritesProvider(child: MyApp(home: homeWidget)),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Widget home;
  const MyApp({Key? key, required this.home}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale value) {
    setState(() => _locale = value);
  }

  @override
  Widget build(BuildContext context) {
    // Access theme manager for light/dark mode
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {'/home': (_) => const TouristHomeScreen(), ...AppRouter.routes},
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ru'),
        Locale('de'),
        Locale('fr'),
        Locale('nl'),
        //Locale('dv'),
      ],
      locale: _locale,

      // Apply Material 3 themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeManager.themeMode,

      home: widget.home,
    );
  }
}

/// Save theme mode to shared preferences
Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  String themeModeString;

  switch (mode) {
    case ThemeMode.light:
      themeModeString = 'light';
      break;
    case ThemeMode.dark:
      themeModeString = 'dark';
      break;
    default:
      themeModeString = 'system';
  }

  await prefs.setString('theme_mode', themeModeString);
}
