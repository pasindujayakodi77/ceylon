import 'package:ceylon/main.dart';
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
  String _role = '';
  bool _loading = true;
  String _selectedLang = 'en';

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data != null) {
      _name.text = data['name'] ?? '';
      _country.text = data['country'] ?? '';
      _email = data['email'] ?? '';
      _role = data['role'] ?? '';
      _selectedLang = data['language'] ?? 'en';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _name.text,
      'country': _country.text,
      'language': _selectedLang,
    });

    // Update app locale
    MyApp.setLocale(context, Locale(_selectedLang));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Profile updated')));
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myProfile)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name'),
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
            Text("Email: $_email"),
            Text("Role: $_role"),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text(AppLocalizations.of(context)!.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
