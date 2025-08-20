import 'dart:io';
import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/main.dart';
import 'package:ceylon/features/reviews/presentation/screens/my_reviews_screen.dart';
import 'package:ceylon/features/profile/data/country_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  String _selectedCountry = '';
  String _email = '';
  bool _isEmailVerified = false;
  String _role = '';
  bool _loading = true;
  String _selectedLang = 'en';
  String? _profileImageUrl;

  // Helper method to get language display name
  String _getLanguageDisplay(String code) {
    switch (code) {
      case 'en':
        return 'English (US)';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'dv':
        return 'ދިވެހި (Dhivehi)';
      case 'ru':
        return 'Русский (Russian)';
      case 'de':
        return 'Deutsch (German)';
      case 'fr':
        return 'Français (French)';
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'nl':
        return 'Nederlands (Dutch)';
      default:
        return code;
    }
  }

  // Image picker instance
  final ImagePicker _picker = ImagePicker();
  // For temporary file storage when selecting a new image
  File? _imageFile;
  // Flag to track if user is uploading a profile image
  bool _isUploadingImage = false;

  Future<void> _loadProfile() async {
    try {
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

      // Ensure the user profile document exists before trying to load it
      await _ensureUserProfileExists();

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final doc = await userDocRef.get();

      // Now we can be confident that doc.exists will be true
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _name.text = data['name'] ?? '';
          _selectedCountry = data['country'] ?? '';
          _role = data['role'] ?? '';
          _selectedLang = data['language'] ?? 'en';
          _profileImageUrl = data['profileImageUrl'];
        }
      } else {
        // This should rarely happen since _ensureUserProfileExists should have created the document
        // But as a fallback, initialize with default values
        _name.text = user.displayName ?? '';
        _selectedCountry = '';
        _role = 'user'; // Default role
        _selectedLang = 'en';
        _profileImageUrl = user.photoURL;
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Continue with empty fields if there's an error
    } finally {
      setState(() => _loading = false);
    }
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

  // Shows a searchable country picker dialog
  void _showCountryPicker(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<Country> filteredCountries = List.from(countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: CeylonTokens.borderRadiusLarge.topLeft,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select your country',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search countries',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: CeylonTokens.borderRadiusMedium,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredCountries = countries.where((country) {
                          return country.name.toLowerCase().contains(
                                value.toLowerCase(),
                              ) ||
                              country.code.toLowerCase().contains(
                                value.toLowerCase(),
                              );
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          title: Text(country.name),
                          trailing: Text(country.code),
                          onTap: () {
                            this.setState(() {
                              _selectedCountry = country.name;
                            });
                            Navigator.pop(context);
                          },
                          selected: country.name == _selectedCountry,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.2),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If user is not logged in, navigate to login screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      // First check if the document exists
      final docSnapshot = await userDocRef.get();

      // Create user data map
      final userData = {
        'name': _name.text,
        'country': _selectedCountry,
        'language': _selectedLang,
        'email': user.email ?? '',
        'role': _role.isNotEmpty ? _role : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docSnapshot.exists) {
        // Update existing document
        await userDocRef.update(userData);
      } else {
        // Create new document with additional fields
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userDocRef.set(userData);
      }

      // Update app locale
      MyApp.setLocale(context, Locale(_selectedLang));

      setState(() => _loading = false);
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
      return;
    }

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

  // Checks if a user profile document exists, creates one if not
  Future<bool> _ensureUserProfileExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final uid = user.uid;
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        // Create a basic profile document if one doesn't exist
        await userDocRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'country': '',
          'role': 'user',
          'language': 'en',
          'profileImageUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true; // Document was created
      } else {
        // Document exists but check if Gmail photo needs to be synchronized
        final data = docSnapshot.data();
        if (data != null &&
            user.photoURL != null &&
            data['profileImageUrl'] == null) {
          // Update with Gmail photo if we don't have a profile image yet
          await userDocRef.update({
            'profileImageUrl': user.photoURL,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return true; // Document already exists
    } catch (e) {
      print('Error ensuring user profile exists: $e');
      return false;
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Upload the image to Firebase Storage
        await _uploadImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      // Upload file
      await storageRef.putFile(_imageFile!);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update profile image URL in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _profileImageUrl = downloadUrl;
        _imageFile = null;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // Show image picker options
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remove current photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Remove profile image
  Future<void> _removeProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Update Firestore to remove the profile image URL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': null, 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Try to delete the file from storage (this may fail if it doesn't exist)
      try {
        await FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg')
            .delete();
      } catch (e) {
        // Ignore error if file doesn't exist
        print('Note: Could not delete storage file: $e');
      }

      setState(() {
        _profileImageUrl = null;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      print('Error removing profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Profile image
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

                          // Loading indicator
                          if (_isUploadingImage)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),

                          // Camera icon for edit hint
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.background,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
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
                      labelText: AppLocalizations.of(context).name,
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

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
                          hintText: 'Select your country',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),

                  // Language field (read-only)
                  TextField(
                    controller: TextEditingController(
                      text: _getLanguageDisplay(_selectedLang),
                    ),
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Language',
                      prefixIcon: Icon(Icons.language),
                      filled: true,
                    ),
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
                    child: Text(AppLocalizations.of(context).saveChanges),
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
