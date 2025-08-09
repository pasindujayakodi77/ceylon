import 'package:flutter/material.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';

class BusinessFeedbackSheet extends StatefulWidget {
  final String businessId;
  const BusinessFeedbackSheet({super.key, required this.businessId});

  @override
  State<BusinessFeedbackSheet> createState() => _BusinessFeedbackSheetState();
}

class _BusinessFeedbackSheetState extends State<BusinessFeedbackSheet> {
  FeedbackReason? _reason;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a reason')));
      return;
    }
    setState(() => _saving = true);
    try {
      await BusinessAnalyticsService.instance.submitFeedback(
        businessId: widget.businessId,
        reason: _reason!,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Feedback sent')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _chip(FeedbackReason r, String label, IconData icon) {
    final selected = _reason == r;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      onSelected: (_) => setState(() => _reason = r),
    );
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
            'Why didn’t you visit/book?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(FeedbackReason.too_far, 'Too far', Icons.directions_walk),
              _chip(
                FeedbackReason.too_expensive,
                'Too expensive',
                Icons.attach_money,
              ),
              _chip(FeedbackReason.closed, 'Closed', Icons.lock_clock),
              _chip(FeedbackReason.crowded, 'Crowded', Icons.groups),
              _chip(FeedbackReason.other, 'Other', Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Optional note',
              hintText: 'Tell us more (helps the business improve)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_saving ? 'Sending…' : 'Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
