// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/business/data/business_repository.dart';

class RequestVerificationSheet extends StatefulWidget {
  final String businessId;
  const RequestVerificationSheet({super.key, required this.businessId});

  @override
  State<RequestVerificationSheet> createState() =>
      _RequestVerificationSheetState();
}

class _RequestVerificationSheetState extends State<RequestVerificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Verification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional context...',
                ),
                minLines: 2,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please provide a note'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _submitting = true);
                              try {
                                final repo = BusinessRepository(
                                  FirebaseFirestore.instance,
                                  FirebaseAuth.instance,
                                );
                                await repo.requestVerification(
                                  widget.businessId,
                                  {'notes': _notes.text.trim()},
                                );
                                if (mounted) Navigator.of(context).pop(true);
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                              } finally {
                                if (mounted)
                                  setState(() => _submitting = false);
                              }
                            },
                      child: Text(_submitting ? 'Submitting...' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
