import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestVerificationSheet extends StatefulWidget {
  final String businessId;
  const RequestVerificationSheet({super.key, required this.businessId});

  @override
  State<RequestVerificationSheet> createState() =>
      _RequestVerificationSheetState();
}

class _RequestVerificationSheetState extends State<RequestVerificationSheet> {
  final _noteCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Avoid duplicate active requests
      final pending = await FirebaseFirestore.instance
          .collection('verification_requests')
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (pending.docs.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already pending review.')),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('verification_requests').add({
        'businessId': widget.businessId,
        'ownerId': uid,
        'status': 'pending',
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'decidedAt': null,
        'decidedBy': null,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Request sent')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Request verification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a note (license, registration, website, social profile) to help the team verify.',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'e.g., Tourism license #12345; website https://…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_sending ? 'Sending…' : 'Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
