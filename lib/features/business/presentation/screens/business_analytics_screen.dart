import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ceylon/features/business/data/business_analytics_service.dart';

/// Displays analytics for the current business, summarising recent activity
/// over the past 30 days. Metrics include profile views, booking intents and
/// engagement rates. Simple bar charts visualise daily trends, and recent
/// feedback is listed for context. This screen is refreshable.
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

  int _sum(String key) {
    return _days.fold<int>(
      0,
      (acc, m) => acc + ((m[key] as num?)?.toInt() ?? 0),
    );
  }

  String _engagementRate() {
    final views = _sum('views');
    if (views == 0) return '0%';
    final engagements = _sum('bookings_whatsapp') + _sum('bookings_form');
    final rate = (engagements / views * 100).toStringAsFixed(1);
    return '$rate%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _businessId == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No business found',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a business to view analytics',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Last 30 Days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummarySection(context),
                  const SizedBox(height: 24),
                  _buildStatsSection(context),
                  const SizedBox(height: 24),
                  _buildFeedbackSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    // Four metrics summarised on two rows
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize_rounded),
                const SizedBox(width: 8),
                Text(
                  'Performance Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _metricCard(
                  icon: Icons.visibility,
                  title: 'Profile Views',
                  value: _sum('views').toString(),
                  color: Colors.blue,
                ),
                _metricCard(
                  icon: Icons.message,
                  title: 'WhatsApp Clicks',
                  value: _sum('bookings_whatsapp').toString(),
                  color: Colors.green,
                ),
                _metricCard(
                  icon: Icons.description,
                  title: 'Form Opens',
                  value: _sum('bookings_form').toString(),
                  color: Colors.orange,
                ),
                _metricCard(
                  icon: Icons.star,
                  title: 'Engagement Rate',
                  value: _engagementRate(),
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    // Build bar charts for each metric. Use simple vertical bars sized proportionally.
    return Column(
      children: [
        _StatCard(
          title: 'Visits',
          value: _sum('views'),
          series: _days.map((d) => (d['views'] as num?)?.toInt() ?? 0).toList(),
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'WhatsApp Intents',
          value: _sum('bookings_whatsapp'),
          series: _days
              .map((d) => (d['bookings_whatsapp'] as num?)?.toInt() ?? 0)
              .toList(),
          color: Colors.green,
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'Form Opens',
          value: _sum('bookings_form'),
          series: _days
              .map((d) => (d['bookings_form'] as num?)?.toInt() ?? 0)
              .toList(),
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 10),
        _StatCard(
          title: 'Favorites (+ / −)',
          value: _sum('favorites_added'),
          series: _days
              .map((d) => (d['favorites_added'] as num?)?.toInt() ?? 0)
              .toList(),
          color: Colors.pink,
          extra: '−${_sum('favorites_removed')}',
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
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
                    contentPadding: EdgeInsets.zero,
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

/// A simple vertical bar chart summarising a single metric over 30 days.
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
    final maxVal = (series.isEmpty ? 1 : series.reduce((a, b) => a > b ? a : b))
        .clamp(1, 999999);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          height: (v / maxVal) * 40.0,
                          color: color.withOpacity(0.35),
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

/// A row representing a feedback reason with a coloured indicator and count.
class _FeedbackRow extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _FeedbackRow({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(count.toString()),
        ],
      ),
    );
  }
}
