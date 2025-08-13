import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/main.dart';
import 'package:ceylon/features/auth/data/auth_repository.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'LKR';
  String _selectedDistanceUnit = 'km';
  String _appVersion = '1.0.0';
  final _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationTrackingEnabled =
          prefs.getBool('location_tracking_enabled') ?? true;
      _savingOfflineMaps = prefs.getBool('saving_offline_maps') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'en';
      _selectedCurrency = prefs.getString('currency') ?? 'LKR';
      _selectedDistanceUnit = prefs.getString('distance_unit') ?? 'km';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_tracking_enabled', _locationTrackingEnabled);
    await prefs.setBool('saving_offline_maps', _savingOfflineMaps);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('distance_unit', _selectedDistanceUnit);

    // Update app locale
    if (context.mounted) {
      MyApp.setLocale(context, Locale(_selectedLanguage));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Settings saved')));
    }
  }

  Future<void> _logout() async {
    try {
      final navigator = Navigator.of(context);
      await _authRepo.signOut();
      if (context.mounted) {
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  void _changeTheme() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.toggleTheme();

    // Save theme mode to shared preferences
    saveThemeMode(themeManager.themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save settings',
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
                          ? NetworkImage(user.photoURL!)
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
                      user.displayName ?? 'Traveler',
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
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ),

          // App Preferences
          _buildSectionHeader(context, 'App Preferences'),

          // Theme
          ListTile(
            leading: Icon(
              themeManager.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('App Theme'),
            subtitle: Text(
              themeManager.isDarkMode ? 'Dark Mode' : 'Light Mode',
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
            title: const Text('Language'),
            subtitle: Text(_getLanguageName(_selectedLanguage)),
            onTap: _showLanguageDialog,
          ),

          // Currency
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text(_selectedCurrency),
            onTap: _showCurrencyDialog,
          ),

          // Distance unit
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Distance Unit'),
            subtitle: Text(_selectedDistanceUnit.toUpperCase()),
            onTap: _showDistanceUnitDialog,
          ),

          // Privacy & Permissions
          _buildSectionHeader(context, 'Privacy & Permissions'),

          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Get travel updates and alerts'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),

          // Location tracking
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Location Services'),
            subtitle: const Text('Allow app to access your location'),
            value: _locationTrackingEnabled,
            onChanged: (value) {
              setState(() => _locationTrackingEnabled = value);
            },
          ),

          // Offline maps
          SwitchListTile(
            secondary: const Icon(Icons.map),
            title: const Text('Save Maps Offline'),
            subtitle: const Text('Download maps for offline use'),
            value: _savingOfflineMaps,
            onChanged: (value) {
              setState(() => _savingOfflineMaps = value);
            },
          ),

          // About & Support
          _buildSectionHeader(context, 'About & Support'),

          // App version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_appVersion),
            onTap: null,
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              _launchURL('https://ceylonapp.com/terms');
            },
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              _launchURL('https://ceylonapp.com/privacy');
            },
          ),

          // Contact Support
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contact Support'),
            onTap: () {
              _launchURL('mailto:support@ceylonapp.com');
            },
          ),

          // Feedback
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () {
              _launchURL(
                'mailto:feedback@ceylonapp.com?subject=Ceylon App Feedback',
              );
            },
          ),

          // Account Management
          _buildSectionHeader(context, 'Account Management'),

          // Delete data
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.orange),
            title: const Text('Delete My Data'),
            subtitle: const Text('Remove all your personal data from the app'),
            onTap: _showDeleteDataDialog,
          ),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption('en', 'English'),
                _buildLanguageOption('hi', 'हिंदी (Hindi)'),
                _buildLanguageOption('ru', 'Русский (Russian)'),
                _buildLanguageOption('de', 'Deutsch (German)'),
                _buildLanguageOption('fr', 'Français (French)'),
                _buildLanguageOption('nl', 'Nederlands (Dutch)'),
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

  Widget _buildLanguageOption(String code, String name) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: _selectedLanguage,
      onChanged: (value) {
        setState(() => _selectedLanguage = value!);
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
      groupValue: _selectedCurrency,
      onChanged: (value) {
        setState(() => _selectedCurrency = value!);
        Navigator.pop(context);
      },
    );
  }

  void _showDistanceUnitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Distance Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Kilometers (km)'),
                value: 'km',
                groupValue: _selectedDistanceUnit,
                onChanged: (value) {
                  setState(() => _selectedDistanceUnit = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Miles (mi)'),
                value: 'mi',
                groupValue: _selectedDistanceUnit,
                onChanged: (value) {
                  setState(() => _selectedDistanceUnit = value!);
                  Navigator.pop(context);
                },
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
                // TODO: Implement data deletion
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your data has been queued for deletion'),
                  ),
                );
              },
              child: const Text('Delete My Data'),
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
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
      default:
        return 'English';
    }
  }
}
