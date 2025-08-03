import 'package:ceylon/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  void _signIn() {
    context.read<AuthBloc>().add(SignInRequested(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("❌ ${state.message}")));
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
                const SnackBar(content: Text("✅ Login Successful")),
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
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                const Text(
                  "Welcome to CEYLON",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.forgotPassword),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signIn,
                  child: state is AuthLoading
                      ? const CircularProgressIndicator()
                      : Text(AppLocalizations.of(context)!.login),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                  onPressed: () {
                    context.read<AuthBloc>().add(GoogleSignInRequested());
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.signup),
                ),
                // ... Phone login option removed ...
              ],
            ),
          );
        },
      ),
    );
  }
}
