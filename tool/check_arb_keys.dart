// FILE: tool/check_arb_keys.dart
import 'dart:convert';
import 'dart:io';

/// A tool to check for consistency across ARB translation files
///
/// This script loads all ARB files in the l10n directory and reports:
/// - Keys present in the base English (app_en.arb) file but missing in other languages
/// - Extra keys present in other languages but missing in the base English file
///
/// Exit codes:
/// - 0: Success, no issues found
/// - 1: Missing translations found
/// - 2: Error reading files or invalid format
void main() async {
  // Configuration
  const baseLanguage = 'en';
  const arbDir = 'lib/l10n';
  const baseFile = 'app_en.arb';

  try {
    print('🔍 Checking ARB files for consistency...');

    // Get directory containing ARB files
    final directory = Directory(arbDir);
    if (!directory.existsSync()) {
      print('❌ Error: Directory $arbDir does not exist');
      exit(2);
    }

    // Find all ARB files
    final arbFiles = directory
        .listSync()
        .where(
          (file) =>
              file is File &&
              file.path.endsWith('.arb') &&
              !file.path.endsWith('.untranslated.arb'),
        )
        .cast<File>()
        .toList();

    if (arbFiles.isEmpty) {
      print('❌ Error: No ARB files found in $arbDir');
      exit(2);
    }

    print('📁 Found ${arbFiles.length} ARB files');

    // Read base language file
    final baseFilePath = '$arbDir/$baseFile';
    final baseFileObj = File(baseFilePath);
    if (!baseFileObj.existsSync()) {
      print('❌ Error: Base language file $baseFilePath not found');
      exit(2);
    }

    // Parse base language file
    final Map<String, dynamic> baseContent;
    try {
      baseContent = json.decode(baseFileObj.readAsStringSync());
    } catch (e) {
      print('❌ Error parsing $baseFilePath: $e');
      exit(2);
    }

    // Extract translatable keys (ignore metadata)
    final baseKeys = <String>{};
    baseContent.forEach((key, value) {
      // Skip metadata keys like @@locale or keys starting with @
      if (key != '@@locale' && !key.startsWith('@')) {
        baseKeys.add(key);
      }
    });

    print(
      '🔤 Base language ($baseLanguage) has ${baseKeys.length} translatable keys',
    );

    bool hasErrors = false;

    // Check each language file
    for (final arbFile in arbFiles) {
      if (arbFile.path.endsWith(baseFile)) continue; // Skip base file

      final filename = arbFile.path.split(Platform.pathSeparator).last;

      // Parse language file
      final Map<String, dynamic> langContent;
      try {
        langContent = json.decode(arbFile.readAsStringSync());
      } catch (e) {
        print('❌ Error parsing $filename: $e');
        hasErrors = true;
        continue;
      }

      // Get language code
      String langCode = 'unknown';
      if (langContent.containsKey('@@locale')) {
        langCode = langContent['@@locale'];
      } else {
        // Try to extract from filename
        final match = RegExp(
          r'app_([a-z]{2}(?:_[A-Z]{2})?).arb',
        ).firstMatch(filename);
        if (match != null) {
          langCode = match.group(1)!;
        }
      }

      // Extract translatable keys for this language
      final langKeys = <String>{};
      langContent.forEach((key, value) {
        if (key != '@@locale' && !key.startsWith('@')) {
          langKeys.add(key);
        }
      });

      print('\n📄 Checking $filename (${langCode})...');
      print('   Found ${langKeys.length} translatable keys');

      // Check for missing translations
      final missingKeys = baseKeys.difference(langKeys);
      if (missingKeys.isNotEmpty) {
        print('❌ Missing ${missingKeys.length} translations:');
        missingKeys.forEach((key) => print('   - $key'));
        hasErrors = true;
      } else {
        print('✅ All base keys are translated');
      }

      // Check for extra keys
      final extraKeys = langKeys.difference(baseKeys);
      if (extraKeys.isNotEmpty) {
        print('⚠️ Found ${extraKeys.length} extra keys not in base language:');
        extraKeys.forEach((key) => print('   - $key'));
      }
    }

    if (hasErrors) {
      print('\n❌ Issues found in ARB files. Please update the translations.');
      exit(1);
    } else {
      print('\n✅ All translations are consistent!');
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
    exit(2);
  }
}
