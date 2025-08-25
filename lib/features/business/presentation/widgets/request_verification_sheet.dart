// FILE: lib/features/business/presentation/widgets/request_verification_sheet.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ceylon/features/business/data/business_repository.dart';

/// A bottom sheet for requesting business verification.
///
/// This allows business owners to submit documentation URLs and notes
/// to platform administrators for verification purposes.
class RequestVerificationSheet extends StatefulWidget {
  final String businessId;
  const RequestVerificationSheet({super.key, required this.businessId});

  @override
  State<RequestVerificationSheet> createState() =>
      _RequestVerificationSheetState();
}

class _RequestVerificationSheetState extends State<RequestVerificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _docsUrlController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _urlValid = false;

  @override
  void dispose() {
    _docsUrlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Validates if the entered URL is properly formatted
  bool _validateUrl(String url) {
    if (url.isEmpty) return false;

    // Simple regex for URL validation
    final urlRegExp = RegExp(
      r'^(http|https)://([\w-]+\.)+[\w-]+(/[\w-./?%&=]*)?$',
      caseSensitive: false,
    );

    return urlRegExp.hasMatch(url);
  }

  /// Attempts to open the provided URL to verify it exists
  Future<void> _checkUrl() async {
    final url = _docsUrlController.text.trim();
    if (!_validateUrl(url)) {
      setState(() {
        _urlValid = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);

      setState(() {
        _urlValid = canLaunch;
      });
    } catch (e) {
      setState(() {
        _urlValid = false;
      });
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Request Business Verification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Information text
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why get verified?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Build trust with customers'),
                      _buildBulletPoint('Appear higher in search results'),
                      _buildBulletPoint('Unlock premium features'),
                      _buildBulletPoint('Receive a verified badge'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Upload Documentation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Text(
                'Please provide a URL to your business documentation (Google Drive, Dropbox, etc.)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),

              // Document URL field
              TextFormField(
                controller: _docsUrlController,
                decoration: InputDecoration(
                  labelText: 'Documentation URL',
                  hintText: 'https://drive.google.com/...',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: _docsUrlController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            _urlValid
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: _urlValid ? Colors.green : Colors.orange,
                          ),
                          onPressed: _checkUrl,
                          tooltip: _urlValid
                              ? 'URL is valid'
                              : 'Check if URL is valid',
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  if (value.isNotEmpty && _validateUrl(value)) {
                    _checkUrl();
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a documentation URL';
                  }
                  if (!_validateUrl(value.trim())) {
                    return 'Please enter a valid URL (starting with http:// or https://)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note to Admins',
                  hintText: 'Any additional details about your business...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Submit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitVerificationRequest(context),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Request',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// Submits the verification request to the repository
  Future<void> _submitVerificationRequest(BuildContext context) async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final docsUrl = _docsUrlController.text.trim();
      final note = _noteController.text.trim();

      // Create verification request via repository
      final repo = BusinessRepository(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );

      await repo.requestVerification(
        widget.businessId,
        docsUrl: docsUrl,
        note: note.isNotEmpty ? note : null,
      );

      // Update the dashboard state via cubit if available
      if (context.mounted) {
        // Close the bottom sheet with success result
        Navigator.of(context).pop(true);

        // Show success toast
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit verification request: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
