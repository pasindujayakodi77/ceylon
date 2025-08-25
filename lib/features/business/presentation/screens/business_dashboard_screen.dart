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
import 'package:firebase_storage/firebase_storage.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  File? _imageFile;
  // These are kept for future upload implementation.
  // ignore: unused_field
  bool _isUploading = false;
  // ignore: unused_field
  String? _uploadedImageUrl;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  // New category-specific controllers
  String? _selectedCategory;
  final _menuUrlCtrl = TextEditingController(); // cafe
  final _openingHoursCtrl = TextEditingController(); // cafe, shop
  final _roomsCtrl = TextEditingController(); // hotel
  final _checkinCtrl = TextEditingController(); // hotel
  final _durationCtrl = TextEditingController(); // tour
  final _meetingPointCtrl = TextEditingController(); // tour
  final _cuisineCtrl = TextEditingController(); // restaurant
  final _seatingCtrl = TextEditingController(); // restaurant
  final _bookingFormCtrl = TextEditingController();
  bool _promoted = false;
  final _promotedWeightCtrl = TextEditingController(text: '10');
  DateTime? _promotedUntil;
  bool _loading = true;
  String? _businessId;

  // ignore: unused_element
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // ignore: unused_element
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isUploading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final basePath = _businessId ?? uid ?? 'unknown';
      final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'business_photos/$basePath/$filename',
      );

      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _uploadedImageUrl = downloadUrl;

      // update local controller and Firestore record if business exists
      setState(() {
        _photoCtrl.text = downloadUrl;
      });

      if (_businessId != null) {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(_businessId!)
            .set({
              'photo': downloadUrl,
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Photo uploaded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _promptForPhotoUrl() async {
    final ctrl = TextEditingController(text: _photoCtrl.text);
    final r = await showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Paste photo URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(ctrl.text.trim()),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    if (r != null && r.isNotEmpty) {
      setState(() {
        _photoCtrl.text = r;
        _imageFile = null; // clear local image when using URL
      });
    }
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
    // dispose new controllers
    _menuUrlCtrl.dispose();
    _openingHoursCtrl.dispose();
    _roomsCtrl.dispose();
    _checkinCtrl.dispose();
    _durationCtrl.dispose();
    _meetingPointCtrl.dispose();
    _cuisineCtrl.dispose();
    _seatingCtrl.dispose();
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
      _selectedCategory = _categoryCtrl.text.isEmpty
          ? null
          : _categoryCtrl.text;
      _bookingFormCtrl.text = (data['bookingFormUrl'] ?? '').toString();

      // load category-specific fields (backwards compatible)
      _menuUrlCtrl.text = (data['menuUrl'] ?? '').toString();
      _openingHoursCtrl.text = (data['openingHours'] ?? '').toString();
      _roomsCtrl.text = (data['roomsAvailable']?.toString() ?? '').toString();
      _checkinCtrl.text = (data['checkinTime'] ?? '').toString();
      _durationCtrl.text = (data['duration'] ?? '').toString();
      _meetingPointCtrl.text = (data['meetingPoint'] ?? '').toString();
      _cuisineCtrl.text = (data['cuisine'] ?? '').toString();
      _seatingCtrl.text = (data['seatingCapacity']?.toString() ?? '')
          .toString();

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
        'category': _selectedCategory ?? _categoryCtrl.text.trim(),
        'bookingFormUrl': _bookingFormCtrl.text.trim().isEmpty
            ? null
            : _bookingFormCtrl.text.trim(),
        'promoted': _promoted,
        'promotedWeight': _safePriority(),
        'promotedUntil': _promotedUntil == null
            ? null
            : Timestamp.fromDate(_promotedUntil!),
        // category-specific fields
        'menuUrl': _menuUrlCtrl.text.trim().isEmpty
            ? null
            : _menuUrlCtrl.text.trim(),
        'openingHours': _openingHoursCtrl.text.trim().isEmpty
            ? null
            : _openingHoursCtrl.text.trim(),
        'roomsAvailable': _roomsCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_roomsCtrl.text.trim()),
        'checkinTime': _checkinCtrl.text.trim().isEmpty
            ? null
            : _checkinCtrl.text.trim(),
        'duration': _durationCtrl.text.trim().isEmpty
            ? null
            : _durationCtrl.text.trim(),
        'meetingPoint': _meetingPointCtrl.text.trim().isEmpty
            ? null
            : _meetingPointCtrl.text.trim(),
        'cuisine': _cuisineCtrl.text.trim().isEmpty
            ? null
            : _cuisineCtrl.text.trim(),
        'seatingCapacity': _seatingCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_seatingCtrl.text.trim()),
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
                    const SizedBox(height: 12),

                    // Quick actions card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BusinessReviewsScreen(),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.reviews),
                                    SizedBox(height: 6),
                                    Text('Reviews'),
                                  ],
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, thickness: 1),
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BusinessAnalyticsScreen(),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.insights),
                                    SizedBox(height: 6),
                                    Text('Analytics'),
                                  ],
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, thickness: 1),
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BusinessEventsScreen(),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.event_available),
                                    SizedBox(height: 6),
                                    Text('Events'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Business form
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // Photo picker / preview (replaces Photo URL field)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Photo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : (_photoCtrl.text.isNotEmpty
                                        ? Image.network(
                                            _photoCtrl.text,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                  ),
                                                ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.photo, size: 48),
                                          )),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Pick Image'),
                              onPressed: () async {
                                await _pickImage();
                                // if user picked an image, update the photo controller with the local path
                                if (_imageFile != null) {
                                  setState(() {
                                    _photoCtrl.text = _imageFile!.path;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.link),
                              label: const Text('Use URL'),
                              onPressed: _promptForPhotoUrl,
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                              onPressed: () async {
                                if (_imageFile == null &&
                                    _photoCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No image selected'),
                                    ),
                                  );
                                  return;
                                }
                                final confirm = await showDialog<bool?>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Remove image?'),
                                    content: const Text(
                                      'This will clear the selected image. It will also remove the photo from your saved business if it is already saved.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(c).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(c).pop(true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                setState(() {
                                  _imageFile = null;
                                  _photoCtrl.text = '';
                                  _uploadedImageUrl = null;
                                });
                                if (_businessId != null) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('businesses')
                                        .doc(_businessId!)
                                        .set({
                                          'photo': null,
                                          'updated_at':
                                              FieldValue.serverTimestamp(),
                                        }, SetOptions(merge: true));
                                  } catch (e) {
                                    // ignore: avoid_print
                                    print(
                                      'Error clearing photo in Firestore: $e',
                                    );
                                  }
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image removed'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload),
                              label: const Text('Upload (optional)'),
                              onPressed: _isUploading ? null : _uploadImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tip: pick a photo for faster selection; you can also paste an externally hosted image URL.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone (WhatsApp)',
                        helperText:
                            'Use international format, e.g., +9477XXXXXXX',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bookingFormCtrl,
                      decoration: InputDecoration(
                        labelText: 'Booking Form URL (Google Form or website)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    // Category selection dropdown with conditional fields
                    DropdownButtonFormField<String>(
                      value:
                          _selectedCategory ??
                          (_categoryCtrl.text.isEmpty
                              ? null
                              : _categoryCtrl.text),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
                        DropdownMenuItem(value: 'hotel', child: Text('Hotel')),
                        DropdownMenuItem(value: 'tour', child: Text('Tour')),
                        DropdownMenuItem(
                          value: 'restaurant',
                          child: Text('Restaurant'),
                        ),
                        DropdownMenuItem(value: 'shop', child: Text('Shop')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _categoryCtrl.text = v ?? '';
                      }),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Select a category'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    // Conditional fields grouped in collapsible sections for clarity
                    if ((_selectedCategory ?? _categoryCtrl.text) == 'cafe')
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Cafe details'),
                        subtitle: const Text(
                          'Optional: menu link and opening hours',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _menuUrlCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Menu URL',
                                    hintText: 'https://example.com/menu',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _openingHoursCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Opening Hours',
                                    hintText:
                                        'e.g., 08:00–20:00 (comma separated for different days)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if ((_selectedCategory ?? _categoryCtrl.text) == 'hotel')
                      ExpansionTile(
                        title: const Text('Hotel details'),
                        subtitle: const Text(
                          'Rooms and check-in information (optional)',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _roomsCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Rooms Available',
                                    hintText: 'Number of rooms available',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      (v != null &&
                                          v.isNotEmpty &&
                                          int.tryParse(v) == null)
                                      ? 'Enter a number'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _checkinCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Check-in Time',
                                    hintText: 'e.g., 14:00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if ((_selectedCategory ?? _categoryCtrl.text) == 'tour')
                      ExpansionTile(
                        title: const Text('Tour details'),
                        subtitle: const Text('Duration and meeting point'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _durationCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Duration',
                                    hintText: 'e.g., 3h or 4 hours',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _meetingPointCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Meeting Point',
                                    hintText: 'Address or landmark',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if ((_selectedCategory ?? _categoryCtrl.text) ==
                        'restaurant')
                      ExpansionTile(
                        title: const Text('Restaurant details'),
                        subtitle: const Text('Cuisine and seating capacity'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _cuisineCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Cuisine',
                                    hintText: 'e.g., Sri Lankan, Italian',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _seatingCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Seating Capacity',
                                    hintText: 'Number of seats',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      (v != null &&
                                          v.isNotEmpty &&
                                          int.tryParse(v) == null)
                                      ? 'Enter a number'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if ((_selectedCategory ?? _categoryCtrl.text) == 'shop')
                      ExpansionTile(
                        title: const Text('Shop details'),
                        subtitle: const Text('Opening hours (optional)'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _openingHoursCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Opening Hours',
                                    hintText: 'e.g., 09:00–18:00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Promotion
                    SwitchListTile.adaptive(
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
                              if (!context.mounted) return;
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 12,
                                  minute: 0,
                                ),
                              );
                              if (!context.mounted) return;
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

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveBusiness,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Info'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
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
