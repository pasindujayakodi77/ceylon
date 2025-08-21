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
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en', 'AU'),
    Locale('en', 'GB'),
    Locale('fr'),
    Locale('hi'),
    Locale('nl'),
    Locale('ru'),
    Locale('si'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Ceylon'**
  String get appName;

  /// Label for the login button or screen
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Label for the signup button or screen
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Link or button for forgotten password recovery
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Button for signing in with Google
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Button or action to log out the user
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Label for settings screen or section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for language selection option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for theme selection option
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Label for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Label for save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for home screen or tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Label for map screen or tab
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Label for itinerary screen or section
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// Label for favorites screen or section
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Label for user profile screen or section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Label for business section or type
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// Label for reviews section
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// Label for analytics section
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Label for events section or calendar
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Label for directions or navigation
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// Button to add item to itinerary
  ///
  /// In en, this message translates to:
  /// **'Add to Itinerary'**
  String get addToItinerary;

  /// Button to add a review
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get addReview;

  /// Label for submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Message shown when no data is available
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get emptyStateNoData;

  /// Label for retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Label for current day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for events upcoming in the current month
  ///
  /// In en, this message translates to:
  /// **'Upcoming this Month'**
  String get upcomingThisMonth;

  /// Filter option to show all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter option to show promotions
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get filterPromotions;

  /// Filter option to show free items
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get filterFree;

  /// Filter option to show family-friendly items
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get filterFamily;

  /// Filter option to show outdoor activities
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get filterOutdoor;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ceylon'**
  String get welcomeToCeylon;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Label for remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Divider text between login options
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Label for Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Text prompting user to sign up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Label for create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Header text on signup screen
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// Instruction text on signup screen
  ///
  /// In en, this message translates to:
  /// **'Please fill in the details below to get started'**
  String get fillDetailsBelow;

  /// Section title for personal information
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Label for country input field
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Label for language selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// Section title for account information
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// Label for password confirmation field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Label for role selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// Label for tourist role option
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get tourist;

  /// Title for password reset screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Header text on forgot password screen
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordQuestion;

  /// Instructions for password reset
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get resetPasswordInstructions;

  /// Label for email address input
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// Button text for sending password reset link
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Confirmation message after sending reset email
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get emailSent;

  /// Detailed message after sending reset email
  ///
  /// In en, this message translates to:
  /// **'If an account exists with this email, you\'ll receive a password reset link shortly. Please check your email inbox and spam folder.'**
  String get resetEmailSentMessage;

  /// Success message after login
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// Success message after account creation
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccessfully;

  /// Button text to save an item to favorites
  ///
  /// In en, this message translates to:
  /// **'Save to Favorites'**
  String get saveFavorite;

  /// Button text to remove an item from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFavorite;

  /// Status message after an item is updated
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;

  /// Title for the profile screen
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Label for name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Button text for saving changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Message shown when favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Button text to edit the user's profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Section header for app preferences in settings
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// Label for light mode theme
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Label for currency selection
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Label for distance unit selection
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnit;

  /// Section header for privacy and permissions settings
  ///
  /// In en, this message translates to:
  /// **'Privacy & Permissions'**
  String get privacyAndPermissions;

  /// Title for saving maps offline option
  ///
  /// In en, this message translates to:
  /// **'Save Maps Offline'**
  String get saveMapsOffline;

  /// Subtitle explaining offline maps option
  ///
  /// In en, this message translates to:
  /// **'Download maps for offline use'**
  String get saveMapsOfflineSubtitle;

  /// Section header for about and support
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get aboutAndSupport;

  /// Label for the application version
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Link label to view the terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Link label to view the privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Label for contacting support
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Label for sending feedback via email
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// Section header for account management options
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// Action label to delete the user's data
  ///
  /// In en, this message translates to:
  /// **'Delete My Data'**
  String get deleteMyData;

  /// Subtitle explaining data deletion
  ///
  /// In en, this message translates to:
  /// **'Remove all your personal data from the app'**
  String get deleteMyDataSubtitle;

  /// Label for signing out of the app
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Title for push notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Subtitle for push notifications explaining purpose
  ///
  /// In en, this message translates to:
  /// **'Get travel updates and alerts'**
  String get pushNotificationsSubtitle;

  /// Title for location services toggle
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// Subtitle explaining location access
  ///
  /// In en, this message translates to:
  /// **'Allow app to access your location'**
  String get locationServicesSubtitle;

  /// Fallback display name for anonymous users
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get traveler;
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
    'si',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'AU':
            return AppLocalizationsEnAu();
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

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
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
