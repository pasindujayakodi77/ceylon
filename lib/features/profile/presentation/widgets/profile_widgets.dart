import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/profile/data/country_data.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedCountry;
  final String? selectedLang;
  final Function() onCountryPickerTap;

  const ProfileFormFields({
    super.key,
    required this.nameController,
    required this.selectedCountry,
    this.selectedLang,
    required this.onCountryPickerTap,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: CeylonTokens.spacing16),

        // Name field
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).name,
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
          ),
        ),
        const SizedBox(height: CeylonTokens.spacing16),

        // Country field
        GestureDetector(
          onTap: onCountryPickerTap,
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(text: selectedCountry),
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
            text: selectedLang != null
                ? _getLanguageDisplay(selectedLang!)
                : '',
          ),
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Preferred Language',
            prefixIcon: const Icon(Icons.language),
            filled: true,
          ),
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String nameInitial;
  final bool isUploadingImage;
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    required this.profileImageUrl,
    required this.nameInitial,
    required this.isUploadingImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
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
                // Use the user's uploaded image when available, otherwise fall back
                // to the ui-avatars service so the avatar looks the same as on Home
                backgroundImage: NetworkImage(
                  profileImageUrl ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameInitial.isNotEmpty ? nameInitial : 'User')}&background=random',
                ),
                // If there's no profile image, still show the initial on top
                child: profileImageUrl == null
                    ? Text(
                        nameInitial.isNotEmpty
                            ? nameInitial.toUpperCase()
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
          if (isUploadingImage)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: const Center(
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
                border: Border.all(color: colorScheme.surface, width: 2),
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
    );
  }
}

class EmailVerificationTile extends StatelessWidget {
  final String email;
  final bool isEmailVerified;
  final VoidCallback onSendVerification;

  const EmailVerificationTile({
    super.key,
    required this.email,
    required this.isEmailVerified,
    required this.onSendVerification,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: CeylonTokens.spacing16),
      child: ListTile(
        leading: Icon(Icons.email_outlined, color: colorScheme.primary),
        title: Row(
          children: [
            const Text('Sign-in Email'),
            const SizedBox(width: 8),
            if (isEmailVerified)
              Chip(
                label: const Text('Verified'),
                labelStyle: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            if (!isEmailVerified)
              TextButton.icon(
                onPressed: onSendVerification,
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
    );
  }
}

class CountryPickerBottomSheet extends StatefulWidget {
  final String selectedCountry;
  final Function(String) onCountrySelected;

  const CountryPickerBottomSheet({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  late List<Country> filteredCountries;

  @override
  void initState() {
    super.initState();
    filteredCountries = List.from(countries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      filteredCountries = filterCountries(value);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onChanged: _onSearchChanged,
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
                    widget.onCountrySelected(country.name);
                    Navigator.pop(context);
                  },
                  selected: country.name == widget.selectedCountry,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
