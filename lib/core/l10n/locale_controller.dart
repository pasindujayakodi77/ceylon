// FILE: lib/core/l10n/locale_controller.dart
import 'package:ceylon/features/settings/data/language_codes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing application locale
///
/// This controller allows changing the app's language at runtime
/// and persists the selection to SharedPreferences.
class LocaleController extends ChangeNotifier {
  /// The current locale of the application
  Locale? _current;

  /// SharedPreferences key for storing the selected language
  static const String _prefsKey = 'app_language';

  /// Default constructor
  LocaleController() {
    loadSaved();
  }

  /// Get the current locale
  Locale? get current => _current;

  /// Set a new locale and notify listeners
  Future<void> setLocale(Locale? newLocale) async {
    if (newLocale == _current) return;

    // Set current locale, but use a safe locale for actual Flutter localization
    _current = newLocale != null ? getSafeLocale(newLocale) : null;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove(_prefsKey);
    } else {
      final languageCode = newLocale.languageCode;
      final countryCode = newLocale.countryCode;

      // Store both language and country code if available
      if (countryCode != null) {
        await prefs.setString(_prefsKey, '${languageCode}_$countryCode');
      } else {
        await prefs.setString(_prefsKey, languageCode);
      }
    }
  }

  /// Get a safe locale that is supported by the Material and Cupertino libraries
  Locale getSafeLocale(Locale locale) {
    // Handle languages that need special treatment
    switch (locale.languageCode) {
      case 'dv': // Dhivehi
        // Fall back to English for Dhivehi since it isn't fully supported by Material/Cupertino yet
        return const Locale('en');
      case 'en':
        // Only support 'en' without country code for consistency
        return const Locale('en');
      default:
        return locale;
    }
  }

  /// Save the current locale to Firestore for the logged-in user
  /// This allows syncing language preference across devices
  Future<void> saveToFirestore(String userId) async {
    try {
      if (_current == null) return;

      // Get language code string in Firestore format
      final languageString = LanguageCodes.getFirestoreLanguageCode(_current!);

      // Update user document with merge to handle cases where document might not exist yet
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'language': languageString,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving language to Firestore: $e');
    }
  }

  /// Load the saved locale from SharedPreferences or set the default locale
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_prefsKey);

    if (savedLocale != null) {
      // Check if the saved locale includes a country code
      if (savedLocale.contains('_')) {
        final parts = savedLocale.split('_');
        _current = Locale(parts[0], parts[1]);
      } else {
        _current = Locale(savedLocale);
      }
    } else {
      // Default to English if no locale is saved
      _current = const Locale('en');
    }
    notifyListeners();
  }

  /// Try to load the user's preferred language from Firestore
  /// Call this method after a user logs in to sync the language preference
  ///
  /// Returns true if language was successfully loaded and applied,
  /// false if no language was found or there was an error
  Future<bool> loadFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data != null && data.containsKey('language')) {
        final languageCode = data['language'] as String;
        debugPrint('Found language preference in Firestore: $languageCode');

        // Check if language code includes country code
        if (languageCode.contains('_')) {
          final parts = languageCode.split('_');
          await setLocale(Locale(parts[0], parts[1]));
        } else {
          await setLocale(Locale(languageCode));
        }
        return true;
      } else {
        debugPrint(
          'No language preference found in Firestore for user $userId',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error loading language from Firestore: $e');
      // Re-throw to allow caller to handle the error (for retry logic)
      rethrow;
    }
  }
}
