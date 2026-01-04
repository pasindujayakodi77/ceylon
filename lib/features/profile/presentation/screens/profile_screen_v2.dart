// ignore_for_file: avoid_print
import 'dart:io';
import 'package:ceylon/features/reviews/presentation/screens/my_reviews_screen.dart';
import 'package:ceylon/features/profile/data/country_data.dart';
import 'package:ceylon/features/business/presentation/screens/business_home_screen.dart';
import 'package:ceylon/features/home/presentation/screens/home_screen_new.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/features/common/helpers/image_provider_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/features/settings/data/language_codes.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/design_system/widgets/radio_group.dart';

class ProfileScreenV2 extends StatefulWidget {
  const ProfileScreenV2({super.key});

  @override
  State<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends State<ProfileScreenV2> {
  final _name = TextEditingController();
  String _selectedCountry = '';
  String _email = '';
  bool _isEmailVerified = false;
  String _role = '';
  bool _loading = true;
  Locale _selectedLocale = const Locale('en');
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  String? _bio;
  List<String> _interests = [];
  String _currency = 'USD';

  final _bioController = TextEditingController();
  final _interestController = TextEditingController();

  final List<String> _availableInterests = [
    'Beach',
    'Culture',
    'Food',
    'History',
    'Nature',
    'Photography',
    'Adventure',
    'Wildlife',
    'Temples',
    'Local Markets',
  ];

  Widget _buildLanguageOption(Locale locale, String name, Locale groupValue) {
    final bool isRtl = LanguageCodes.isRtlLanguage(locale);
    final bool isSelected =
        groupValue.languageCode == locale.languageCode &&
        groupValue.countryCode == locale.countryCode;

    return Builder(
      builder: (context) {
        final group = RadioGroup.of<Locale>(context);
        // ignore: deprecated_member_use
        return RadioListTile<Locale>(
          title: Text(
            name,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          value: locale,
          // ignore: deprecated_member_use
          groupValue: group?.groupValue,
          // ignore: deprecated_member_use
          onChanged: group?.onChanged,
          secondary: isRtl
              ? const Icon(Icons.format_textdirection_r_to_l)
              : locale.countryCode != null
              ? const Icon(Icons.flag_outlined)
              : null,
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      _email = user.email ?? 'No email found';
      _isEmailVerified = user.emailVerified;

      await _ensureUserProfileExists();

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final doc = await userDocRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _name.text = data['name'] ?? '';
            _selectedCountry = data['country'] ?? '';
            // Normalize older 'user' role to 'tourist' for consistency
            final rawRole = data['role'] as String? ?? '';
            _role = (rawRole == 'user') ? 'tourist' : rawRole;
            _selectedLocale = Locale(data['language'] ?? 'en');
            _profileImageUrl = data['profileImageUrl'];
            _bio = data['bio'] ?? '';
            _bioController.text = _bio ?? '';
            _interests = List<String>.from(data['interests'] ?? []);
            _currency = data['preferredCurrency'] ?? 'USD';
          });
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<bool> _ensureUserProfileExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final doc = await userDocRef.get();

      if (!doc.exists) {
        await userDocRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          // Align default role with sign-up flow and Google sign-in
          'role': 'tourist',
          'language': 'en',
          'interests': [],
          'preferredCurrency': 'USD',
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error ensuring user profile exists: $e');
      return false;
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(user.uid)
            .child('profile')
            .child('${user.uid}.jpg');

        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isUploadingImage = true);

      // Delete from Storage
      if (_profileImageUrl != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(user.uid)
            .child('profile')
            .child('${user.uid}.jpg');
        await storageRef.delete();
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': FieldValue.delete()},
      );

      setState(() {
        _profileImageUrl = null;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLanguagePicker() {
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
                  child: ListView(
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
                                RadioGroup<Locale>(
                                  groupValue: _selectedLocale,
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
                                  },
                                  child: Column(
                                    children: locales.map(
                                      (locale) => _buildLanguageOption(
                                        locale,
                                        LanguageCodes.getLanguageName(locale),
                                        _selectedLocale,
                                      ),
                                    ).toList(),
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

  void _showCurrencyPicker() {
    final currencies = ['USD', 'EUR', 'GBP', 'LKR', 'INR', 'AUD'];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return ListTile(
                title: Text(currency),
                trailing: _currency == currency
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _currency = currency);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showInterestPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Your Interests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableInterests.length,
                  itemBuilder: (context, index) {
                    final interest = _availableInterests[index];
                    return CheckboxListTile(
                      title: Text(interest),
                      value: _interests.contains(interest),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _interests.add(interest);
                          } else {
                            _interests.remove(interest);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      final docSnapshot = await userDocRef.get();
      final previousRole = docSnapshot.exists
          ? (docSnapshot.data()?['role'] as String? ?? 'tourist')
          : 'tourist';

      final userData = {
        'name': _name.text,
        'country': _selectedCountry,
        'language': _selectedLocale.languageCode,
        'email': user.email ?? '',
        'role': _role.isNotEmpty ? _role : 'tourist',
        'updatedAt': FieldValue.serverTimestamp(),
        // Trim bio to avoid accidental leading/trailing whitespace
        'bio': _bioController.text.trim(),
        'interests': _interests,
        'preferredCurrency': _currency,
      };

      // Use merge set to avoid accidentally overwriting other fields
      // If the document does not exist, include createdAt so it's set on create
      if (!docSnapshot.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await userDocRef.set(userData, SetOptions(merge: true));

      // Locale is updated by the LocaleController in _showLanguagePicker

      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('✅ Profile updated'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Handle role changes - navigate to the appropriate screen
        final newRole = userData['role'] as String;
        if (previousRole != newRole) {
          // User changed roles, navigate to the appropriate screen
          if (newRole == 'business') {
            // Navigate to business home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BusinessHomeScreen()),
            );
            return;
          } else if (newRole == 'tourist') {
            // Navigate to tourist home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TouristHomeScreen()),
            );
            return;
          }
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error saving profile: ${e.toString()}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error saving profile: $e');
    }
  }

  void _showCountryPicker(BuildContext context) async {
    // Return the selected country name from the dialog
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        // Keep a mutable filtered list in the closure scope so StatefulBuilder can update it
        List<Country> filtered = List.from(countries);

        return AlertDialog(
          title: const Text('Select Country'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search countries...',
                      ),
                      onChanged: (value) {
                        setState(() {
                          filtered = filterCountries(value.trim());
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text('No countries found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final country = filtered[index];
                                return ListTile(
                                  title: Text(country.name),
                                  trailing: Text(country.code),
                                  onTap: () {
                                    Navigator.of(context).pop(country.name);
                                  },
                                  selected: country.name == _selectedCountry,
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  selectedTileColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.2),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    // Update parent state if user selected a country
    if (selected != null && selected.isNotEmpty) {
      setState(() => _selectedCountry = selected);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _bioController.dispose();
    _interestController.dispose();
    super.dispose();
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
          AppLocalizations.of(context).myProfile,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with Cover Image
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/onboarding/beach.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black26,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 24,
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: safeNetworkImageProvider(
                              _profileImageUrl,
                            ),
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
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Profile Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: true,
                      hintText:
                          'Tell us about yourself and your travel interests...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showCountryPicker(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: _selectedCountry,
                        ),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).country,
                          prefixIcon: const Icon(Icons.public),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          filled: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Travel Preferences Section
                  Text(
                    'Travel Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interests Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Add Interests'),
                        onPressed: _showInterestPicker,
                      ),
                      ..._interests.map(
                        (interest) => Chip(
                          label: Text(interest),
                          onDeleted: () {
                            setState(() {
                              _interests.remove(interest);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Currency Preference
                  ListTile(
                    title: const Text('Preferred Currency'),
                    subtitle: Text(_currency),
                    leading: const Icon(Icons.currency_exchange),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showCurrencyPicker,
                    tileColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Language Preference
                  ListTile(
                    title: const Text('App Language'),
                    subtitle: Text(
                      LanguageCodes.getLanguageName(_selectedLocale),
                    ),
                    leading: const Icon(Icons.language),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showLanguagePicker,
                    tileColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Account Section
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Row(
                        children: [
                          const Text('Sign-in Email'),
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
                            ),
                        ],
                      ),
                      subtitle: Text(_email),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role selector — lets users switch between tourist and business
                  DropdownButtonFormField<String>(
                    // Ensure legacy 'user' value doesn't cause Dropdown mismatch
                    initialValue: (_role == 'user')
                        ? 'tourist'
                        : (_role.isNotEmpty ? _role : 'tourist'),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'tourist',
                        child: Text('Tourist'),
                      ),
                      DropdownMenuItem(
                        value: 'business',
                        child: Text('Business'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _role = val);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Reviews Button
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
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.rate_review),
                        SizedBox(width: 8),
                        Text('View My Reviews'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  FilledButton(
                    onPressed: _saveProfile,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(AppLocalizations.of(context).saveChanges),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
