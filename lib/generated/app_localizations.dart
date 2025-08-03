import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_dv.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('dv'),
    Locale('en'),
    Locale('fr'),
    Locale('hi'),
    Locale('nl'),
    Locale('ru'),
  ];

  /// The title of the application, shown in the app bar and launcher.
  ///
  /// In en, this message translates to:
  /// **'CEYLON'**
  String get appTitle;

  /// Label for the login button or screen.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Label for the signup button or screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Label for the email input field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for the password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Link or button for forgotten password recovery.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Button or link to create a new account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Label for the name input field.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// Label for the country input field or selector.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Button to save changes made by the user.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button or action to log out the user.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Label for the user's profile section.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Label for the favorites section or button.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Message shown when the user has no favorites yet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Label for the trip title field.
  ///
  /// In en, this message translates to:
  /// **'Trip Title'**
  String get tripTitle;

  /// Button to add a new day to the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Add Day'**
  String get addDay;

  /// Button to save the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Save Itinerary'**
  String get saveItinerary;

  /// Label for the user's trips section.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// Button to view the attractions map.
  ///
  /// In en, this message translates to:
  /// **'View Attractions Map'**
  String get viewAttractionsMap;

  /// Button to share content.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button to get directions.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// Button to remove an item from favorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFavorite;

  /// Button to save an item as favorite.
  ///
  /// In en, this message translates to:
  /// **'Save to Favorites'**
  String get saveFavorite;

  /// Technical string for flutter localization generation.
  ///
  /// In en, this message translates to:
  /// **'flutter gen-l10n'**
  String get flutterGenL10n;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'dv',
    'en',
    'fr',
    'hi',
    'nl',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'dv':
      return AppLocalizationsDv();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'nl':
      return AppLocalizationsNl();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
