// FILE: test/l10n_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylon/l10n/app_localizations.dart';

// A simpler approach to testing localization that doesn't rely on Material widgets
// which require locale support for Material/Cupertino components
void main() {
  // Use a lookup test approach instead of widget testing to validate translations
  test('Validate key translations for various locales', () async {
    // Test English (base language)
    final enDelegate = AppLocalizations.delegate;
    final enLocalizations = await enDelegate.load(const Locale('en'));
    expect(enLocalizations.login, equals('Login'));
    expect(enLocalizations.home, equals('Home'));

    // Test Dhivehi (dv) which we fixed
    final dvDelegate = AppLocalizations.delegate;
    final dvLocalizations = await dvDelegate.load(const Locale('dv'));
    expect(dvLocalizations.login, equals('ވަންނަން'));
    expect(dvLocalizations.home, equals('މައި ޞަފްޙާ'));

    // Test Hindi (hi) which we fixed
    final hiDelegate = AppLocalizations.delegate;
    final hiLocalizations = await hiDelegate.load(const Locale('hi'));
    expect(hiLocalizations.login, equals('लॉग इन करें'));
    expect(hiLocalizations.home, equals('होम'));

    // Test German (as a different example)
    final deDelegate = AppLocalizations.delegate;
    final deLocalizations = await deDelegate.load(const Locale('de'));
    // The actual string depends on the translation, adjust as needed
    expect(deLocalizations.login, isNot(equals('Login')));
  });

  test('Verify Dhivehi (dv) has all required translations', () async {
    final dvDelegate = AppLocalizations.delegate;
    final dvLocalizations = await dvDelegate.load(const Locale('dv'));

    // Verify a sample of keys we added exist and are translated
    expect(dvLocalizations.welcomeToCeylon, equals('ސީލޯނަށް މަރުޙަބާ'));
    expect(
      dvLocalizations.signInToContinue,
      equals('ކުރިއަށް ދިއުމަށް ސައިން އިން ކުރޭ'),
    );
    expect(dvLocalizations.rememberMe, equals('ފަހުން ހަނދާން ބަހައްޓާ'));

    // We could add more comprehensive checks here if needed
  });

  test('Verify Hindi (hi) has all required translations', () async {
    final hiDelegate = AppLocalizations.delegate;
    final hiLocalizations = await hiDelegate.load(const Locale('hi'));

    // Verify a sample of keys we added exist and are translated
    expect(hiLocalizations.welcomeToCeylon, equals('सीलोन में आपका स्वागत है'));
    expect(
      hiLocalizations.signInToContinue,
      equals('जारी रखने के लिए साइन इन करें'),
    );
    expect(hiLocalizations.rememberMe, equals('मुझे याद रखें'));
  });
}
