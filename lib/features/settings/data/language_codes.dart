// FILE: lib/features/settings/data/language_codes.dart

import 'package:flutter/material.dart';

/// Provides language mapping and utility functions for the app
class LanguageCodes {
  /// Map of language codes to their display names
  static Map<Locale, String> getLanguageMap() {
    return {
      // English variants
      const Locale('en'): 'English (US)',
      const Locale('en', 'GB'): 'English (UK)',
      const Locale('en', 'AU'): 'English (Australia)',

      // Other languages
      const Locale('hi'): 'हिंदी (Hindi)',
      const Locale('ru'): 'Русский (Russian)',
      const Locale('de'): 'Deutsch (German)',
      const Locale('fr'): 'Français (French)',
      const Locale('nl'): 'Nederlands (Dutch)',
      const Locale('dv'): 'ދިވެހި (Dhivehi)',
      const Locale('si'): 'සිංහල (Sinhala)',
    };
  }

  /// Get a language display name from a Locale
  static String getLanguageName(Locale locale) {
    // Check for specific language and country combinations
    if (locale.languageCode == 'en' && locale.countryCode == 'GB') {
      return 'English (UK)';
    } else if (locale.languageCode == 'en' && locale.countryCode == 'AU') {
      return 'English (Australia)';
    }

    // Check for language code only
    switch (locale.languageCode) {
      case 'en':
        return 'English (US)';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'ru':
        return 'Русский (Russian)';
      case 'de':
        return 'Deutsch (German)';
      case 'fr':
        return 'Français (French)';
      case 'nl':
        return 'Nederlands (Dutch)';
      case 'dv':
        return 'ދިވެހި (Dhivehi)';
      case 'si':
        return 'සිංහල (Sinhala)';
      default:
        return locale.languageCode;
    }
  }

  /// Get the string representation of a locale for Firestore storage
  static String getFirestoreLanguageCode(Locale locale) {
    if (locale.countryCode != null) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  /// Check if a language is written right-to-left (RTL)
  static bool isRtlLanguage(Locale locale) {
    // List of RTL language codes
    const rtlLanguages = ['ar', 'dv', 'fa', 'he', 'ur'];
    return rtlLanguages.contains(locale.languageCode);
  }

  /// Group languages by script/region for display purposes
  static List<Map<String, dynamic>> getLanguageGroups() {
    return [
      {
        'name': 'English Variants',
        'locales': [
          const Locale('en'),
          const Locale('en', 'GB'),
          const Locale('en', 'AU'),
        ],
      },
      {
        'name': 'South Asian Languages',
        'locales': [const Locale('hi'), const Locale('si')],
      },
      {
        'name': 'European Languages',
        'locales': [
          const Locale('de'),
          const Locale('fr'),
          const Locale('nl'),
          const Locale('ru'),
        ],
      },
      {
        'name': 'RTL Languages',
        'locales': [const Locale('dv')],
      },
    ];
  }
}
