import 'package:ceylon/design_system/tokens.dart';
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
        title: const Text('📈 Business Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: CeylonTokens.seedColor),
            )
          : (_businessId == null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    'No business found',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  SizedBox(height: CeylonTokens.spacing8),
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
              color: CeylonTokens.seedColor,
              child: ListView(
                padding: EdgeInsets.all(CeylonTokens.spacing16),
                children: [
                  Text(
                    'Last 30 Days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: CeylonTokens.spacing16),
                  _buildSummarySection(),
                  SizedBox(height: CeylonTokens.spacing24),
                  _buildStatsSection(),
                  SizedBox(height: CeylonTokens.spacing24),
                  _buildFeedbackSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: CeylonTokens.borderRadiusMedium,
        boxShadow: CeylonTokens.shadowSmall,
      ),
      child: Padding(
        padding: EdgeInsets.all(CeylonTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: CeylonTokens.spacing8),
                Text(
                  'Performance Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: CeylonTokens.spacing16),

            // Metric cards in a grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: CeylonTokens.spacing12,
              crossAxisSpacing: CeylonTokens.spacing12,
              childAspectRatio: 3 / 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  icon: Icons.visibility,
                  title: 'Profile Views',
                  value: _sum('views').toString(),
                  color: Colors.blue,
                ),
                _buildMetricCard(
                  icon: Icons.message,
                  title: 'WhatsApp Clicks',
                  value: _sum('bookings_whatsapp').toString(),
                  color: Colors.green,
                ),
                _buildMetricCard(
                  icon: Icons.description,
                  title: 'Form Opens',
                  value: _sum('bookings_form').toString(),
                  color: Colors.orange,
                ),
                _buildMetricCard(
                  icon: Icons.star,
                  title: 'Engagement Rate',
                  value: _getEngagementRate(),
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEngagementRate() {
    final views = _sum('views');
    if (views == 0) return '0%';
    final engagements = _sum('bookings_whatsapp') + _sum('bookings_form');
    final rate = (engagements / views * 100).toStringAsFixed(1);
    return '$rate%';
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: CeylonTokens.borderRadiusMedium,
      ),
      padding: EdgeInsets.all(CeylonTokens.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: CeylonTokens.spacing8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: CeylonTokens.spacing4),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
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
