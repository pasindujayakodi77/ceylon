import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/main.dart';
import 'package:ceylon/features/reviews/presentation/screens/my_reviews_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();
  String _email = '';
  bool _isEmailVerified = false;
  String _role = '';
  bool _loading = true;
  String _selectedLang = 'en';
  String? _profileImageUrl;

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If user is not logged in, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // Get the sign-in email and verification status from Firebase Auth
    _email = user.email ?? 'No email found';
    _isEmailVerified = user.emailVerified;

    final uid = user.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data != null) {
      _name.text = data['name'] ?? '';
      _country.text = data['country'] ?? '';
      _role = data['role'] ?? '';
      _selectedLang = data['language'] ?? 'en';
      _profileImageUrl = data['profileImageUrl'];
    }

    setState(() => _loading = false);
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mark_email_read, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verification email sent. Please check your inbox and then refresh profile.',
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'Refresh',
                textColor: Colors.white,
                onPressed: _refreshUserStatus,
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshUserStatus() async {
    setState(() => _loading = true);

    try {
      // Reload the user to get the latest verification status
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      await _loadProfile();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If user is not logged in, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    final uid = user.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _name.text,
      'country': _country.text,
      'language': _selectedLang,
    });

    // Update app locale
    MyApp.setLocale(context, Locale(_selectedLang));

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('✅ Profile updated'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: CeylonTokens.borderRadiusMedium,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myProfile,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with avatar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(CeylonTokens.spacing24),
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile-avatar',
                      child: Material(
                        elevation: 4,
                        shadowColor: Colors.black38,
                        shape: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? Text(
                                  _name.text.isNotEmpty
                                      ? _name.text[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: CeylonTokens.spacing16),
                    Text(
                      _role,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(CeylonTokens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile form section
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

                  // Profile form fields
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

                  TextField(
                    controller: _country,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.country,
                      prefixIcon: const Icon(Icons.public),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

                  DropdownButtonFormField<String>(
                    value: _selectedLang,
                    decoration: InputDecoration(
                      labelText: 'Preferred Language',
                      prefixIcon: const Icon(Icons.language),
                      filled: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text("English")),
                      DropdownMenuItem(value: 'hi', child: Text("हिंदी")),
                      DropdownMenuItem(value: 'dv', child: Text("ދިވެހި")),
                      DropdownMenuItem(value: 'ru', child: Text("Русский")),
                      DropdownMenuItem(value: 'de', child: Text("Deutsch")),
                      DropdownMenuItem(value: 'fr', child: Text("Français")),
                      DropdownMenuItem(value: 'nl', child: Text("Nederlands")),
                    ],
                    onChanged: (val) => setState(() => _selectedLang = val!),
                  ),
                  const SizedBox(height: CeylonTokens.spacing24),

                  // Account information section
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

                  // Non-editable fields displayed in cards
                  Card(
                    margin: const EdgeInsets.only(
                      bottom: CeylonTokens.spacing16,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Row(
                        children: [
                          Text('Sign-in Email'),
                          const SizedBox(width: 8),
                          if (_isEmailVerified)
                            Chip(
                              label: const Text('Verified'),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: colorScheme.primaryContainer,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            )
                          else
                            Chip(
                              label: const Text('Unverified'),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: colorScheme.errorContainer,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _email,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (!_isEmailVerified)
                            TextButton.icon(
                              onPressed: _sendVerificationEmail,
                              icon: const Icon(Icons.mail_outline, size: 16),
                              label: const Text('Send verification email'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing16,
                        vertical: CeylonTokens.spacing8,
                      ),
                    ),
                  ),

                  // My Reviews button
                  const SizedBox(height: CeylonTokens.spacing16),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyReviewsScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rate_review),
                        const SizedBox(width: CeylonTokens.spacing8),
                        const Text('✏️ View My Reviews'),
                      ],
                    ),
                  ),

                  // Save button
                  const SizedBox(height: CeylonTokens.spacing32),
                  FilledButton(
                    onPressed: _saveProfile,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: Text(AppLocalizations.of(context)!.saveChanges),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
