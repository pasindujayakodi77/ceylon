import 'package:ceylon/features/business/presentation/screens/business_analytics_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_events_screen.dart';
import 'package:ceylon/features/business/presentation/screens/business_reviews_screen.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';
import 'package:ceylon/features/profile/presentation/screens/profile_screen_v2.dart';
import 'package:ceylon/features/business/presentation/widgets/request_verification_sheet.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  File? _imageFile;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _bookingFormCtrl = TextEditingController();
  bool _promoted = false;
  final _promotedWeightCtrl = TextEditingController(text: '10');
  DateTime? _promotedUntil;
  bool _loading = true;
  String? _businessId;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isUploading = true;
    });
    // Upload logic here
    setState(() {
      _isUploading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    _phoneCtrl.dispose();
    _categoryCtrl.dispose();
    _bookingFormCtrl.dispose();
    _promotedWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _loadBusinessData() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _businessId = doc.id;
      final data = doc.data();

      _nameCtrl.text = (data['name'] ?? '').toString();
      _descCtrl.text = (data['description'] ?? '').toString();
      _photoCtrl.text = (data['photo'] ?? '').toString();
      _phoneCtrl.text = (data['phone'] ?? '').toString();
      _categoryCtrl.text = (data['category'] ?? '').toString();
      _bookingFormCtrl.text = (data['bookingFormUrl'] ?? '').toString();

      _promoted = (data['promoted'] as bool?) ?? false;
      _promotedWeightCtrl.text = (data['promotedWeight']?.toString() ?? '10');
      _promotedUntil = (data['promotedUntil'] as Timestamp?)?.toDate();
    }
    setState(() => _loading = false);
  }

  int _safePriority() {
    final n = int.tryParse(_promotedWeightCtrl.text.trim());
    if (n == null) return 10;
    return n.clamp(1, 100);
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final p = v.trim();
    final ok = RegExp(r'^\+?\d{7,15}$').hasMatch(p.replaceAll(' ', ''));
    if (!ok) return 'Use international format, e.g. +94771234567';
    return null;
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final data = {
        'ownerId': uid,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'photo': _photoCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'bookingFormUrl': _bookingFormCtrl.text.trim().isEmpty
            ? null
            : _bookingFormCtrl.text.trim(),
        'promoted': _promoted,
        'promotedWeight': _safePriority(),
        'promotedUntil': _promotedUntil == null
            ? null
            : Timestamp.fromDate(_promotedUntil!),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_businessId == null) {
        final ref = await FirebaseFirestore.instance
            .collection('businesses')
            .add({...data, 'created_at': FieldValue.serverTimestamp()});
        _businessId = ref.id;
      } else {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(_businessId)
            .set(data, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Business info saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Business Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreenV2()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, business user 👋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick actions
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.reviews),
                          label: const Text('Respond to Reviews'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessReviewsScreen(),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.insights),
                          label: const Text('View Analytics'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessAnalyticsScreen(),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event_available),
                          label: const Text('Manage Events'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessEventsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Business form
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _photoCtrl,
                      decoration: const InputDecoration(labelText: 'Photo URL'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone (WhatsApp)',
                        helperText:
                            'Use international format, e.g., +9477XXXXXXX',
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bookingFormCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Booking Form URL (Google Form or website)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g., cafe, hotel, tour)',
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Promotion
                    SwitchListTile(
                      title: const Text('Promote on Home Carousel'),
                      subtitle: const Text(
                        'Show this business on Tourist Home',
                      ),
                      value: _promoted,
                      onChanged: (v) => setState(() => _promoted = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _promotedWeightCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Promotion Priority (1–100)',
                              helperText: 'Higher shows earlier',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event),
                            label: Text(
                              _promotedUntil == null
                                  ? 'Set End Date'
                                  : 'Ends: ${DateFormat('yyyy-MM-dd HH:mm').format(_promotedUntil!)}',
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final d = await showDatePicker(
                                context: context,
                                initialDate:
                                    _promotedUntil ??
                                    now.add(const Duration(days: 7)),
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (d == null) return;
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 12,
                                  minute: 0,
                                ),
                              );
                              setState(() {
                                _promotedUntil = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  t?.hour ?? 0,
                                  t?.minute ?? 0,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_businessId != null)
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('businesses')
                                .doc(_businessId!)
                                .get(),
                            builder: (context, snap) {
                              final isVerified =
                                  (snap.data?.data()?['verified'] as bool?) ??
                                  false;
                              return isVerified
                                  ? const VerifiedStatusPill(verified: true)
                                  : const VerifiedStatusPill(verified: false);
                            },
                          ),
                        const Spacer(),
                        if (_businessId != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Request Verification'),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => RequestVerificationSheet(
                                  businessId: _businessId!,
                                ),
                              );
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saveBusiness,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Info'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class VerifiedStatusPill extends StatelessWidget {
  final bool verified;
  const VerifiedStatusPill({super.key, required this.verified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFE3F2FD) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: verified ? const Color(0xFF90CAF9) : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.help_outline,
            size: 16,
            color: verified ? const Color(0xFF1E88E5) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'Verified' : 'Not verified',
            style: TextStyle(
              color: verified ? const Color(0xFF1565C0) : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
