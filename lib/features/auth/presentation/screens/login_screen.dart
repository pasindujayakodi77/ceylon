import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_button.dart';
import 'package:ceylon/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'signup_screen.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ceylon/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        SignInRequested(_email.text, _password.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
            () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
              final data = doc.data();
              final langCode = data?['language'] ?? 'en';
              MyApp.setLocale(context, Locale(langCode));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Login successful"),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleRouter()),
                );
              });
            }();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: CeylonTokens.spacing24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: CeylonTokens.spacing32),

                    // App logo or brand element
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            CeylonTokens.radiusMedium,
                          ),
                        ),
                        child: Icon(
                          Icons.travel_explore,
                          size: 48,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Welcome title
                    Text(
                      "Welcome to Ceylon",
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ),

                    const SizedBox(height: CeylonTokens.spacing8),

                    Text(
                      "Sign in to continue",
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                    ),

                    const SizedBox(height: CeylonTokens.spacing32),

                    // Email field
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.email,
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
                      delay: const Duration(milliseconds: 400),
                    ),

                    const SizedBox(height: CeylonTokens.spacing20),

                    // Password field
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
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
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (_) => _signIn(),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 500),
                    ),

                    const SizedBox(height: CeylonTokens.spacing8),

                    // Remember me & Forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                            Text("Remember me", style: textTheme.bodySmall),
                          ],
                        ),

                        // Forgot password
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.forgotPassword,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Sign in button
                    CeylonButton.primary(
                      label: AppLocalizations.of(context)!.login,
                      onPressed: state is AuthLoading ? null : _signIn,
                      isLoading: state is AuthLoading,
                      isFullWidth: true,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 700),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Or divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CeylonTokens.spacing16,
                          ),
                          child: Text(
                            "OR",
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 800),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Google sign in button
                    CeylonButton.secondary(
                      label: "Sign in with Google",
                      onPressed: state is AuthLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                              GoogleSignInRequested(),
                            ),
                      isFullWidth: true,
                      leadingIcon: FontAwesomeIcons.google,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 900),
                    ),

                    const SizedBox(height: CeylonTokens.spacing32),

                    // Create account prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.signup,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 1000),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),
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
