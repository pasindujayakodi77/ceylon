import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/core/navigation/app_router.dart';
import 'package:ceylon/core/utils/localization_fallback.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/features/auth/data/auth_gate.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:ceylon/features/home/presentation/screens/home_screen_new.dart';
import 'package:ceylon/features/itinerary/data/itinerary_repository.dart';
import 'package:ceylon/features/reviews/providers/reviews_provider.dart';
import 'package:ceylon/services/favorites_provider.dart';
import 'package:ceylon/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/l10n/app_localizations.dart';

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

  // Initialize locale controller
  final localeController = LocaleController();
  await localeController.loadSaved();

  Widget homeWidget = seenOnboarding
      ? (isSignedIn ? const RoleRouter() : const LoginScreen())
      : const OnboardingScreen();

  runApp(
    MultiProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepo: authRepo)),
        ChangeNotifierProvider.value(value: themeManager),
        Provider<ItineraryRepository>(create: (_) => ItineraryRepository()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider.value(value: localeController),
      ],
      child: FavoritesProvider(
        child: AuthGate(child: MyApp(home: homeWidget)),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({Key? key, required this.home}) : super(key: key);

  /// Static method to set locale from other screens
  /// This maintains backwards compatibility with existing code
  /// while using the new LocaleController
  static void setLocale(BuildContext context, Locale locale) {
    final localeController = Provider.of<LocaleController>(
      context,
      listen: false,
    );
    localeController.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    // Access theme manager for light/dark mode
    final themeManager = Provider.of<ThemeManager>(context);
    // Access locale controller
    final localeController = Provider.of<LocaleController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {'/home': (_) => const TouristHomeScreen(), ...AppRouter.routes},
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Localization configuration
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        // For any locale not supported by Material/Cupertino, fall back to English
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeController.current,
      localeListResolutionCallback: (locales, supportedLocales) {
        // First try exact match including country code
        if (locales != null) {
          for (var locale in locales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }
          }
          // Then try just language match without country code
          for (var locale in locales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
          }
        }
        // If no match, fall back to English
        return const Locale('en');
      },

      // App title uses localized string
      onGenerateTitle: (BuildContext context) {
        return AppLocalizations.of(context).appName;
      },

      // Apply Material 3 themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeManager.themeMode,

      // Use automatic RTL directionality based on selected locale
      // This ensures proper RTL layout for languages like Dhivehi
      home: Builder(
        builder: (context) {
          // Define RTL language codes for proper text direction
          const rtlLanguages = ['ar', 'fa', 'he', 'ur', 'dv'];

          // Get current locale and check if it's RTL
          final currentLocale = Localizations.localeOf(context);
          final isRtl = rtlLanguages.contains(currentLocale.languageCode);

          // Wrap the main content with proper text direction
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: home,
          );
        },
      ),
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
