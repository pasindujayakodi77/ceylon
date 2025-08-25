import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

/// Screen for creating a new business
class BusinessCreateScreen extends StatefulWidget {
  const BusinessCreateScreen({super.key});

  @override
  State<BusinessCreateScreen> createState() => _BusinessCreateScreenState();
}

class _BusinessCreateScreenState extends State<BusinessCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _businessRepository = BusinessRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bookingFormUrlController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  List<String> _businessPhotos = [];
  File? _mainPhotoFile;

  final _categories = [
    'Food & Dining',
    'Accommodation',
    'Attractions',
    'Adventure & Tours',
    'Shopping',
    'Transportation',
    'Wellness & Spa',
    'Entertainment',
    'Services',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _bookingFormUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _mainPhotoFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<String?> _uploadMainPhoto() async {
    if (_mainPhotoFile == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileName =
          '${const Uuid().v4()}${path.extension(_mainPhotoFile!.path)}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('businesses/${user.uid}')
          .child(fileName);

      final uploadTask = storageRef.putFile(_mainPhotoFile!);
      final taskSnapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a business'),
          ),
        );
        return;
      }

      // Upload main photo if selected
      String? mainPhotoUrl;
      if (_mainPhotoFile != null) {
        mainPhotoUrl = await _uploadMainPhoto();
        if (mainPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload main photo')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create business object
      final businessId = FirebaseFirestore.instance
          .collection('businesses')
          .doc()
          .id;
      final now = Timestamp.now();

      // Create the base business data
      final Map<String, dynamic> businessData = {
        'id': businessId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'ownerId': user.uid,
        'phone': _phoneController.text,
        'verified': false,
        'promoted': false,
        'promotedWeight': 0,
        'ratingAvg': 0.0,
        'ratingCount': 0,
        'updatedAt': now,
      };

      // Add optional fields
      if (mainPhotoUrl != null) {
        businessData['photo'] = mainPhotoUrl;
      }

      if (_businessPhotos.isNotEmpty) {
        businessData['photoUrls'] = _businessPhotos;
      }

      if (_websiteController.text.isNotEmpty) {
        businessData['website'] = _websiteController.text;
      }

      if (_emailController.text.isNotEmpty) {
        businessData['contactEmail'] = _emailController.text;
      }

      if (_addressController.text.isNotEmpty) {
        businessData['location'] = _addressController.text;
      }

      if (_bookingFormUrlController.text.isNotEmpty) {
        businessData['bookingFormUrl'] = _bookingFormUrlController.text;
      }

      // Create business from data
      final business = Business.fromJson(businessData, id: businessId);

      // Save to repository
      await _businessRepository.upsertBusiness(business);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business created successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating business: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Business')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Main Photo Selection
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            image: _mainPhotoFile != null
                                ? DecorationImage(
                                    image: FileImage(_mainPhotoFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _mainPhotoFile == null
                              ? const Icon(
                                  Icons.business,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickMainImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Business Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name*',
                      hintText: 'Enter your business name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a business name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category*',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description*',
                      hintText: 'Describe your business',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number*',
                      hintText: 'Enter your business phone',
                      border: OutlineInputBorder(),
                      prefixText: '+',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email*',
                      hintText: 'Enter your business email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address*',
                      hintText: 'Enter your business address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Website (Optional)
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website (Optional)',
                      hintText: 'Enter your business website',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  // Booking Form URL (Optional)
                  TextFormField(
                    controller: _bookingFormUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Booking Form URL (Optional)',
                      hintText: 'Enter URL for booking forms',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _createBusiness,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Create Business'),
                  ),
                ],
              ),
            ),
    );
  }
}
