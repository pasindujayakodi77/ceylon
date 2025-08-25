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
  int _rating = 0; // 0 = not set
  final Map<String, bool> _categories = {
    'service': false,
    'price': false,
    'location': false,
  };
  int _nps = 0; // 0-10
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
        rating: _rating > 0 ? _rating : null,
        nps: _nps > 0 ? _nps : null,
        categories: _categories.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
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
              _chip(FeedbackReason.tooFar, 'Too far', Icons.directions_walk),
              _chip(
                FeedbackReason.tooExpensive,
                'Too expensive',
                Icons.attach_money,
              ),
              _chip(FeedbackReason.closed, 'Closed', Icons.lock_clock),
              _chip(FeedbackReason.crowded, 'Crowded', Icons.groups),
              _chip(FeedbackReason.other, 'Other', Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 12),
          // Rating 1-5 stars
          Text('Rating (1-5)'),
          Row(
            children: List.generate(5, (i) {
              final v = i + 1;
              return IconButton(
                icon: Icon(
                  _rating >= v ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = v),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Categories checkboxes
          Text('What was affected?'),
          Wrap(
            spacing: 8,
            children: _categories.keys.map((k) {
              return FilterChip(
                label: Text(k[0].toUpperCase() + k.substring(1)),
                selected: _categories[k]!,
                onSelected: (s) => setState(() => _categories[k] = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // NPS 0-10
          Text('On a scale 0-10 how likely are you to recommend?'),
          Slider(
            min: 0,
            max: 10,
            divisions: 10,
            value: _nps.toDouble(),
            label: _nps.toString(),
            onChanged: (v) => setState(() => _nps = v.toInt()),
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
