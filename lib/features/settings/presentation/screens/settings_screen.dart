import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/features/auth/data/auth_repository.dart';
import 'package:ceylon/features/settings/data/language_codes.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:ceylon/services/firebase_messaging_service.dart';
import 'package:ceylon/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/features/common/helpers/image_provider_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ceylon/features/admin/data/admin_config.dart';
// note: deletion logic implemented inline; services not required here
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _savingOfflineMaps = false;
  bool _isAdmin = false;
  bool _adminUiEnabledPref = false;
  Locale _selectedLocale = const Locale('en');
  String _selectedCurrency = 'LKR';
  String _selectedDistanceUnit = 'km';
  String _appVersion = '1.0.0';
  final _authRepo = AuthRepository();
  LocationService? _locationService;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
    _initializeServices();
    _checkAdminClaim();
  }

  Future<void> _initializeServices() async {
    _locationService = await LocationService.getInstance();
    setState(() {
      _locationTrackingEnabled = _locationService!.isEnabled;
      _notificationsEnabled = FCMService.isEnabled;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadSettings() async {
    final localeController = Provider.of<LocaleController>(
      context,
      listen: false,
    );
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationTrackingEnabled =
          prefs.getBool('location_tracking_enabled') ?? true;
      _savingOfflineMaps = prefs.getBool('saving_offline_maps') ?? false;
      if (localeController.current != null) {
        _selectedLocale = localeController.current!;
      }
      _selectedCurrency = prefs.getString('currency') ?? 'LKR';
      _selectedDistanceUnit = prefs.getString('distance_unit') ?? 'km';
      _adminUiEnabledPref = prefs.getBool('admin_ui_enabled') ?? false;
    });
  }

  Future<void> _checkAdminClaim() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims ?? {};
      final isAdmin = claims['admin'] == true;
      final shouldShowAdmin =
          isAdmin ||
          AdminConfig.forceEnableAdminUi ||
          _adminUiEnabledPref ||
          (AdminConfig.allowAdminInDebug &&
              !bool.fromEnvironment('dart.vm.product'));
      if (!mounted) return;
      setState(() => _isAdmin = shouldShowAdmin);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveSettings() async {
    final localeController = Provider.of<LocaleController>(
      context,
      listen: false,
    );
    final prefs = await SharedPreferences.getInstance();

    // Update notifications service
    await FCMService.setEnabled(_notificationsEnabled);

    // Update location service
    if (_locationService != null) {
      await _locationService!.setEnabled(_locationTrackingEnabled);
    }

    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_tracking_enabled', _locationTrackingEnabled);
    await prefs.setBool('saving_offline_maps', _savingOfflineMaps);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('distance_unit', _selectedDistanceUnit);

    // Update app locale - already saved by the controller
    await localeController.setLocale(_selectedLocale);

    // Save language to Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await localeController.saveToFirestore(user.uid);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).save)));
  }

  Future<void> _logout() async {
    try {
      await _authRepo.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  void _changeTheme() async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.toggleTheme();

    // Save theme mode to shared preferences
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;

    switch (themeManager.themeMode) {
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

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: AppLocalizations.of(context).save,
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          // User info card
          if (user != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: user.photoURL != null
                          ? safeNetworkImageProvider(user.photoURL)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : user.email?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.displayName ?? AppLocalizations.of(context).traveler,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      user.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: Text(AppLocalizations.of(context).editProfile),
                    ),
                  ],
                ),
              ),
            ),

          // App Preferences
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).appPreferences,
          ),

          // Theme
          ListTile(
            leading: Icon(
              themeManager.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(AppLocalizations.of(context).theme),
            subtitle: Text(
              themeManager.isDarkMode
                  ? AppLocalizations.of(context).darkMode
                  : AppLocalizations.of(context).lightMode,
            ),
            onTap: _changeTheme,
            trailing: Switch(
              value: themeManager.isDarkMode,
              onChanged: (_) => _changeTheme(),
            ),
          ),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context).language),
            subtitle: Text(_getLanguageName(_selectedLocale)),
            onTap: _showLanguageDialog,
          ),

          // Currency
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(AppLocalizations.of(context).currency),
            subtitle: Text(_selectedCurrency),
            onTap: _showCurrencyDialog,
          ),

          // Distance unit
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text(AppLocalizations.of(context).distanceUnit),
            subtitle: Text(_selectedDistanceUnit.toUpperCase()),
            onTap: _showDistanceUnitDialog,
          ),

          // Privacy & Permissions
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).privacyAndPermissions,
          ),

          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(AppLocalizations.of(context).pushNotifications),
            subtitle: Text(
              AppLocalizations.of(context).pushNotificationsSubtitle,
            ),
            value: _notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // If enabling notifications, request permission
                await FCMService.setEnabled(true);
                // Load the current state after permission request
                setState(() => _notificationsEnabled = FCMService.isEnabled);
              } else {
                // Simply disable notifications
                setState(() => _notificationsEnabled = false);
              }
            },
          ),

          // Location tracking
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: Text(AppLocalizations.of(context).locationServices),
            subtitle: Text(
              AppLocalizations.of(context).locationServicesSubtitle,
            ),
            value: _locationTrackingEnabled,
            onChanged: (value) async {
              if (value && _locationService != null) {
                // If enabling location, request permission
                await _locationService!.requestPermission();
                final locationEnabled = await _locationService!
                    .isLocationEnabled();
                setState(() => _locationTrackingEnabled = locationEnabled);
              } else {
                // Simply disable location tracking
                setState(() => _locationTrackingEnabled = value);
              }
            },
          ),

          // Offline maps
          SwitchListTile(
            secondary: const Icon(Icons.map),
            title: Text(AppLocalizations.of(context).saveMapsOffline),
            subtitle: Text(
              AppLocalizations.of(context).saveMapsOfflineSubtitle,
            ),
            value: _savingOfflineMaps,
            onChanged: (value) {
              setState(() => _savingOfflineMaps = value);
            },
          ),

          // About & Support
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).aboutAndSupport,
          ),

          // App version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).appVersion),
            subtitle: Text(_appVersion),
            onTap: null,
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(AppLocalizations.of(context).termsOfService),
            onTap: () {
              _launchURL('https://ceylonapp.com/terms');
            },
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(AppLocalizations.of(context).privacyPolicy),
            onTap: () {
              _launchURL('https://ceylonapp.com/privacy');
            },
          ),

          // Contact Support
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(AppLocalizations.of(context).contactSupport),
            onTap: () {
              _launchURL('mailto:support@ceylonapp.com');
            },
          ),

          // Feedback
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(AppLocalizations.of(context).sendFeedback),
            onTap: () {
              _launchURL(
                'mailto:feedback@ceylonapp.com?subject=Ceylon App Feedback',
              );
            },
          ),

          // Local toggle for enabling admin UI (debug builds)
          if (!bool.fromEnvironment('dart.vm.product'))
            SwitchListTile(
              secondary: const Icon(Icons.developer_mode),
              title: const Text('Enable admin UI (local)'),
              value: _adminUiEnabledPref,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('admin_ui_enabled', v);
                if (!mounted) return;
                setState(() => _adminUiEnabledPref = v);
                _checkAdminClaim();
              },
            ),

          // Admin tools (visible only to users with admin claim)
          if (_isAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.purple,
              ),
              title: const Text('Admin'),
              subtitle: const Text('Verification requests & tools'),
              onTap: () => Navigator.pushNamed(context, '/admin'),
            ),

          // Account Management
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).accountManagement,
          ),

          // Delete data
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.orange),
            title: Text(AppLocalizations.of(context).deleteMyData),
            subtitle: Text(AppLocalizations.of(context).deleteMyDataSubtitle),
            onTap: _showDeleteDataDialog,
          ),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(AppLocalizations.of(context).signOut),
            onTap: _showLogoutConfirmation,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).language,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: RadioGroup<Locale>(
                    value: _selectedLocale,
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedLocale = value);
                      Navigator.pop(context);

                      // Apply the language change immediately
                      final localeController = Provider.of<LocaleController>(
                        context,
                        listen: false,
                      );
                      await localeController.setLocale(value);

                      // Save language to Firestore if user is logged in
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await localeController.saveToFirestore(user.uid);
                      }

                      // Show a confirmation message
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context).language} ${AppLocalizations.of(context).updated}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    children: [
                      for (var index = 0; index < LanguageCodes.getLanguageGroups().length; index++) ...[
                        Builder(
                          builder: (context) {
                            final group = LanguageCodes.getLanguageGroups()[index];
                            final String groupName = group['name'] as String;
                            final List<Locale> locales =
                                group['locales'] as List<Locale>;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    groupName,
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                ...locales.map(
                                  (locale) => _buildLanguageOption(
                                    locale,
                                    LanguageCodes.getLanguageName(locale),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (index < LanguageCodes.getLanguageGroups().length - 1)
                          const Divider(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageOption(Locale locale, String name) {
    final bool isRtl = LanguageCodes.isRtlLanguage(locale);
    final bool isSelected =
        _selectedLocale.languageCode == locale.languageCode &&
        _selectedLocale.countryCode == locale.countryCode;

    return RadioListTile<Locale>(
      title: Text(
        name,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      value: locale,
      secondary: isRtl
          ? const Icon(Icons.format_textdirection_r_to_l)
          : locale.countryCode != null
          ? const Icon(Icons.flag_outlined)
          : null,
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              value: _selectedCurrency,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                  Navigator.pop(context);
                }
              },
              children: [
                _buildCurrencyOption('LKR', 'Sri Lankan Rupee (LKR)'),
                _buildCurrencyOption('USD', 'US Dollar (USD)'),
                _buildCurrencyOption('EUR', 'Euro (EUR)'),
                _buildCurrencyOption('GBP', 'British Pound (GBP)'),
                _buildCurrencyOption('INR', 'Indian Rupee (INR)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
    );
  }

  void _showDistanceUnitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Distance Unit'),
          content: RadioGroup<String>(
            value: _selectedDistanceUnit,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDistanceUnit = value);
                Navigator.pop(context);
              }
            },
            children: [
              RadioListTile<String>(
                title: const Text('Kilometers (km)'),
                value: 'km',
              ),
              RadioListTile<String>(
                title: const Text('Miles (mi)'),
                value: 'mi',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete My Data'),
          content: const Text(
            'This will delete all your personal data including saved trips, reviews, and preferences. This action cannot be undone.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _deleteUserData();
              },
              child: const Text('Delete My Data'),
            ),
          ],
        );
      },
    );
  }

  /// Delete all user data from Firestore and Firebase Storage, then sign out.
  Future<void> _deleteUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).deleteMyData} failed: not signed in',
          ),
        ),
      );
      return;
    }

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    // Show progress
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).deleteMyData}...'),
        ),
      );
    }

    try {
      // 1) Delete profile image from Storage if exists
      try {
        final storageRef = storage
            .ref()
            .child('users')
            .child(uid)
            .child('profile')
            .child('$uid.jpg');
        await storageRef.delete();
      } catch (_) {
        // ignore errors if file not found
      }

      // 2) Delete known subcollections under users/{uid}
      final userRef = firestore.collection('users').doc(uid);

      // Helper to delete all documents in a collection
      Future<void> deleteCollection(CollectionReference col) async {
        const batchSize = 50;
        while (true) {
          final snap = await col.limit(batchSize).get();
          if (snap.docs.isEmpty) break;
          final batch = firestore.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      // List of subcollections we know the app uses
      final subcollections = [
        'favorites',
        'itineraries',
        'my_reviews',
        'itineraries',
        'notifications',
      ];

      for (final name in subcollections) {
        final col = userRef.collection(name);
        await deleteCollection(col);
      }

      // 3) Delete any trip_templates created by the user
      try {
        final templates = await firestore
            .collection('trip_templates')
            .where('createdBy', isEqualTo: uid)
            .get();
        for (final doc in templates.docs) {
          await firestore.collection('trip_templates').doc(doc.id).delete();
        }
      } catch (_) {}

      // 4) Remove user's reviews from places collection (best-effort)
      try {
        final myReviewsSnap = await userRef.collection('my_reviews').get();
        for (final doc in myReviewsSnap.docs) {
          final placeId = doc.id;
          final reviewId = doc.data()['reviewId'] as String?;
          if (reviewId != null) {
            final reviewRef = firestore
                .collection('places')
                .doc(placeId)
                .collection('reviews')
                .doc(reviewId);
            await reviewRef.delete();
          }
        }
      } catch (_) {}

      // 5) Finally delete the user document
      try {
        await userRef.delete();
      } catch (_) {}

      // 6) Sign the user out and navigate to login
      await _authRepo.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).deleteMyData} successful',
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting data: ${e.toString()}')),
      );
    }
  }

  String _getLanguageName(Locale locale) {
    return LanguageCodes.getLanguageName(locale);
  }
}
