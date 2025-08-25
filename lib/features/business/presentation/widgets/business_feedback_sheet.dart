// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ceylon/features/business/data/business_repository.dart';

class BusinessFeedbackSheet extends StatefulWidget {
  final String businessId;
  const BusinessFeedbackSheet({super.key, required this.businessId});

  @override
  State<BusinessFeedbackSheet> createState() => _BusinessFeedbackSheetState();
}

class _BusinessFeedbackSheetState extends State<BusinessFeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  int? _rating;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
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
                'Send Feedback',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _rating,
                items: List.generate(
                  5,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1} ★')),
                ),
                decoration: const InputDecoration(labelText: 'Rating'),
                validator: (v) =>
                    (v == null || v < 1) ? 'Please select a rating' : null,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                decoration: const InputDecoration(labelText: 'Message'),
                minLines: 2,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a message'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sending
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _sending = true);
                              try {
                                final repo = BusinessRepository(
                                  FirebaseFirestore.instance,
                                  FirebaseAuth.instance,
                                );
                                await repo.submitFeedback(
                                  widget.businessId,
                                  message: _message.text.trim(),
                                  rating: _rating,
                                );
                                if (mounted) Navigator.of(context).pop(true);
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                              } finally {
                                if (mounted) setState(() => _sending = false);
                              }
                            },
                      child: Text(_sending ? 'Sending...' : 'Send'),
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
