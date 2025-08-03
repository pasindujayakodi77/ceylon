import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ceylon/features/auth/presentation/screens/role_router.dart';
import 'package:ceylon/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String _selectedRole = 'tourist'; // default
  String _selectedLang = 'en';

  void _signUp() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
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
                const SnackBar(content: Text("✅ Account Created")),
              );
              Future.delayed(const Duration(milliseconds: 400), () {
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
                const SizedBox(height: 40),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.name,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLang,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Language',
                  ),
                  items: const [
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
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Select Role'),
                  items: const [
                    DropdownMenuItem(value: 'tourist', child: Text('Tourist')),
                    DropdownMenuItem(
                      value: 'business',
                      child: Text('Business'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signUp,
                  child: state is AuthLoading
                      ? const CircularProgressIndicator()
                      : Text(AppLocalizations.of(context)!.createAccount),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
