import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_app_bar.dart';
import 'package:ceylon/design_system/widgets/ceylon_button.dart';
import 'package:ceylon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        setState(() {
          _sent = true;
          _isLoading = false;
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).emailSent),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('user-not-found')
                  ? "No account found with this email"
                  : "Error sending reset link: ${e.toString()}",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: CeylonAppBar(
        title: AppLocalizations.of(context).resetPassword,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(CeylonTokens.spacing24),
            children: [
              const SizedBox(height: CeylonTokens.spacing16),

              // Header section
              Text(
                AppLocalizations.of(context).forgotPasswordQuestion,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().slideY(
                begin: 0.3,
                end: 0,
                curve: Curves.easeOutQuad,
              ),

              const SizedBox(height: CeylonTokens.spacing8),

              Text(
                    AppLocalizations.of(context).resetPasswordInstructions,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                  .animate(delay: 100.ms)
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: CeylonTokens.spacing32),

              // Email field
              TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).emailAddress,
                      hintText: AppLocalizations.of(context).email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          CeylonTokens.radiusMedium,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _sendResetEmail(),
                  )
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: CeylonTokens.spacing32),

              // Submit button
              CeylonButton.primary(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    label: _isLoading
                        ? "Sending..."
                        : AppLocalizations.of(context).sendResetLink,
                    leadingIcon: _isLoading ? null : Icons.send,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  )
                  .animate(delay: 300.ms)
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

              if (_sent) ...[
                const SizedBox(height: CeylonTokens.spacing24),

                // Success message
                Container(
                  padding: const EdgeInsets.all(CeylonTokens.spacing16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      CeylonTokens.radiusMedium,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: CeylonTokens.spacing8),
                          Text(
                            AppLocalizations.of(context).emailSent,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CeylonTokens.spacing8),
                      Text(
                        AppLocalizations.of(context).resetEmailSentMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
