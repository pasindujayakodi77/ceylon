import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_app_bar.dart';
import 'package:ceylon/design_system/widgets/ceylon_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/features/profile/data/country_data.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import '../bloc/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'tourist'; // default
  String _selectedLang = 'en';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleSignupSuccess() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final localeController = Provider.of<LocaleController>(
      context,
      listen: false,
    );
    await localeController.loadFromFirestore(uid);
    if (!mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).accountCreatedSuccessfully),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleRouter()),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // Form validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Country is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _password.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      // Use context.read<AuthBloc>() to access the bloc and add the event
      context.read<AuthBloc>().add(
        SignUpRequested(
          _email.text,
          _password.text,
          _selectedRole,
          _name.text,
          _country.text,
          _selectedLang,
        ),
      );
    }
  }

  // Reusable country picker dialog that returns the selected country name
  Future<void> _showCountryPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        // Use the same countries list from profile's country_data
        final all = List.of(countries);
        List<Country> filtered = all;

        return AlertDialog(
          title: const Text('Select country'),
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
                        hintText: 'Search countries',
                      ),
                      onChanged: (value) {
                        final q = value.trim().toLowerCase();
                        setState(() {
                          filtered = q.isEmpty
                              ? all
                              : all
                                    .where(
                                      (c) => c.name.toLowerCase().contains(q),
                                    )
                                    .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No countries found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                return ListTile(
                                  title: Text(c.name),
                                  trailing: Text(c.code),
                                  onTap: () =>
                                      Navigator.of(context).pop(c.name),
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

    if (selected != null && selected.isNotEmpty) {
      setState(() => _country.text = selected);
    }
  }

  // Small helper to build the country form field used in the signup form
  Widget _buildCountryField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _showCountryPicker,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _country,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).country,
            prefixIcon: Icon(Icons.public, color: colorScheme.primary),
            suffixIcon: SizedBox(
              width: 84,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_country.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.clear,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _clearCountry,
                    ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
            ),
          ),
          validator: _validateCountry,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }

  void _clearCountry() {
    setState(() => _country.clear());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CeylonAppBar.medium(
        title: AppLocalizations.of(context).signup,
        centerTitle: false,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is AuthSuccess) {
            _handleSignupSuccess();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing24,
                  vertical: CeylonTokens.spacing16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context).createYourAccount,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                    ),

                    const SizedBox(height: CeylonTokens.spacing8),

                    Text(
                      AppLocalizations.of(context).fillDetailsBelow,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Personal Information
                    _buildSectionTitle(
                      context,
                      AppLocalizations.of(context).personalInformation,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Name field
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).fullName,
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 250),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Country field
                    _buildCountryField(context).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Language dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLang,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).preferredLanguage,
                        prefixIcon: Icon(
                          Icons.language,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text("English (US)"),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Text("हिंदī (Hindi)"),
                        ),
                        DropdownMenuItem(
                          value: 'dv',
                          child: Text("ދިވެހި (Dhivehi)"),
                        ),
                        DropdownMenuItem(
                          value: 'ru',
                          child: Text("Русский (Russian)"),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Text("Deutsch (German)"),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text("Français (French)"),
                        ),
                        DropdownMenuItem(
                          value: 'si',
                          child: Text("සිංහල (Sinhala)"),
                        ),
                        DropdownMenuItem(
                          value: 'nl',
                          child: Text("Nederlands (Dutch)"),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedLang = val!),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 350),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Account Information
                    _buildSectionTitle(
                      context,
                      AppLocalizations.of(context).accountInformation,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Email field
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).email,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 450),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Password field
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).password,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 500),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).confirmPassword,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateConfirmPassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 550),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),

                    // Role dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).selectRole,
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'tourist',
                          child: Text(AppLocalizations.of(context).tourist),
                        ),
                        DropdownMenuItem(
                          value: 'business',
                          child: Text(AppLocalizations.of(context).business),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                    ),

                    const SizedBox(height: CeylonTokens.spacing32),

                    // Sign up button
                    CeylonButton.primary(
                      label: AppLocalizations.of(context).createAccount,
                      onPressed: state is AuthLoading ? null : _signUp,
                      isLoading: state is AuthLoading,
                      isFullWidth: true,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 650),
                    ),

                    const SizedBox(height: CeylonTokens.spacing16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
