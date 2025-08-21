import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BusinessAnalyticsScreen extends StatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  State<BusinessAnalyticsScreen> createState() =>
      _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen> {
  String? _businessId;
  bool _loading = true;
  List<Map<String, dynamic>> _days = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bizId = await BusinessAnalyticsService.instance.myBusinessId();
    if (bizId != null) {
      _businessId = bizId;
      _days = await BusinessAnalyticsService.instance.loadLastDays(
        bizId,
        days: 30,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  int _sum(String k) =>
      _days.fold<int>(0, (acc, m) => acc + ((m[k] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Business Analytics (30 days)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_businessId == null)
          ? const Center(child: Text('No business found for your account.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummarySection(),
                const SizedBox(height: 16),
                _buildStatsSection(),
                const SizedBox(height: 16),
                _buildFeedbackSection(),
              ],
            ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Total Visits: ${_sum('views')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total WhatsApp Intents: ${_sum('bookings_whatsapp')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Form Opens: ${_sum('bookings_form')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        _StatCard(
          title: 'Visits',
          value: _sum('views'),
          color: Colors.blue,
          series: _days.map((d) => (d['views'] as num?)?.toInt() ?? 0).toList(),
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'WhatsApp Intents',
          value: _sum('bookings_whatsapp'),
          color: Colors.green,
          series: _days
              .map((d) => (d['bookings_whatsapp'] as num?)?.toInt() ?? 0)
              .toList(),
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'Form Opens',
          value: _sum('bookings_form'),
          color: Colors.deepPurple,
          series: _days
              .map((d) => (d['bookings_form'] as num?)?.toInt() ?? 0)
              .toList(),
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'Favorites (+ / −)',
          value: _sum('favorites_added'),
          extra: '−${_sum('favorites_removed')}',
          color: Colors.pink,
          series: _days
              .map((d) => (d['favorites_added'] as num?)?.toInt() ?? 0)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Feedback Reasons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _FeedbackRow(
          label: 'Too far',
          color: Colors.orange,
          count: _sum('feedback_too_far'),
        ),
        _FeedbackRow(
          label: 'Too expensive',
          color: Colors.redAccent,
          count: _sum('feedback_too_expensive'),
        ),
        _FeedbackRow(
          label: 'Closed',
          color: Colors.brown,
          count: _sum('feedback_closed'),
        ),
        _FeedbackRow(
          label: 'Crowded',
          color: Colors.teal,
          count: _sum('feedback_crowded'),
        ),
        _FeedbackRow(
          label: 'Other',
          color: Colors.grey,
          count: _sum('feedback_other'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('businesses')
              .doc(_businessId!)
              .collection('feedback')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text('No feedback yet.');
            return Column(
              children: [
                for (final d in docs)
                  ListTile(
                    leading: const Icon(Icons.comment),
                    title: Text((d['reason'] as String?) ?? ''),
                    subtitle: Text((d['note'] as String?) ?? '—'),
                    trailing: Text(
                      d['createdAt'] == null
                          ? ''
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format((d['createdAt'] as Timestamp).toDate()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final List<int> series;
  final String? extra;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.series,
    required this.color,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final max = (series.isEmpty ? 1 : (series.reduce((a, b) => a > b ? a : b)))
        .clamp(1, 999999);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${NumberFormat.compact().format(value)}${extra != null ? '  $extra' : ''}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final v in series)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: (v / max) * 40.0,
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _FeedbackRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: count == 0
                  ? 0
                  : null, // indeterminate for non-zero to make it lightweight
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          Text(count.toString()),
        ],
      ),
    );
  }
}
