// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

/// A bottom sheet for collecting user feedback for a business.
///
/// This sheet allows users to quickly provide feedback about their experience
/// with a business using predefined categories and/or custom text.
class BusinessFeedbackSheet extends StatefulWidget {
  final String businessId;
  const BusinessFeedbackSheet({super.key, required this.businessId});

  @override
  State<BusinessFeedbackSheet> createState() => _BusinessFeedbackSheetState();
}

class _BusinessFeedbackSheetState extends State<BusinessFeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _repo = BusinessRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  bool _isSending = false;
  final List<String> _feedbackCategories = [
    'Service',
    'Quality',
    'Price',
    'Cleanliness',
    'Location',
    'Staff',
    'Atmosphere',
    'Speed',
  ];

  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Toggle a feedback category selection
  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  /// Submit the feedback to the repository
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate() && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category or add a comment'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final feedbackText = _feedbackController.text.trim();

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final feedback = BusinessFeedback(
        id: '', // ID will be assigned by Firestore
        userId: uid,
        businessId: widget.businessId,
        text: feedbackText,
        // Pass categories as a parameter if BusinessFeedback supports it
        createdAt: Timestamp.now(),
      );

      await _repo.addFeedback(widget.businessId, feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Your Feedback',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to tell us about?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedbackCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _toggleCategory(category),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Add your comments here...',
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty && _selectedCategories.isEmpty) {
                  return 'Please select a category or enter feedback';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSending ? null : _submitFeedback,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SUBMIT FEEDBACK'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
