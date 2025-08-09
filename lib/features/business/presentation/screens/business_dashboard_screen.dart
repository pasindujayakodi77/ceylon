import 'package:ceylon/features/business/presentation/screens/business_reviews_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../screens/business_analytics_screen.dart';
import '../screens/business_events_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  bool _loading = false;
  String? _businessId;

  // Promotion controls
  bool _promoted = false;
  final _promotedWeightCtrl = TextEditingController(text: '10');
  DateTime? _promotedUntil;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _businessId = doc.id;
      final data = doc.data();
      _nameCtrl.text = data['name'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _photoCtrl.text = data['photo'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _categoryCtrl.text = data['category'] ?? '';
      _promoted = (data['promoted'] as bool?) ?? false;
      _promotedWeightCtrl.text = (data['promotedWeight']?.toString() ?? '10');
      _promotedUntil = (data['promotedUntil'] as Timestamp?)?.toDate();
    }
    setState(() {});
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'ownerId': uid,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'photo': _photoCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'updated_at': FieldValue.serverTimestamp(),
      'promoted': _promoted,
      'promotedWeight': int.tryParse(
        _promotedWeightCtrl.text.trim(),
      )?.clamp(1, 100),
      'promotedUntil': _promotedUntil == null
          ? null
          : Timestamp.fromDate(_promotedUntil!),
    };

    if (_businessId == null) {
      // create new
      final ref = await FirebaseFirestore.instance
          .collection('businesses')
          .add(data);
      _businessId = ref.id;
    } else {
      // update existing
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .update(data);
    }

    setState(() => _loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Business info saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Business Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
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
                      "Welcome, business user 👋",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      icon: const Icon(Icons.reviews),
                      label: const Text('Respond to Reviews'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessReviewsScreen(),
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.insights),
                      label: const Text('View Analytics'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.event_available),
                      label: const Text('Manage Events'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessEventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter a name' : null,
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
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 20),
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
