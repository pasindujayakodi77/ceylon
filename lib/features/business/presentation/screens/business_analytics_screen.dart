import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BusinessAnalyticsScreen extends StatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  State<BusinessAnalyticsScreen> createState() =>
      _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen> {
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      setState(() => _businessId = snap.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dailyMetricsRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('metrics_daily')
        .orderBy(FieldPath.documentId); // YYYY-MM-DD string order is fine

    final reviewsRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('reviews');

    final favoritesRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('favorites');

    return Scaffold(
      appBar: AppBar(title: const Text('📊 Business Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ======== Summary row ========
            StreamBuilder<QuerySnapshot>(
              stream: reviewsRef.snapshots(),
              builder: (_, snap) {
                double avg = 0;
                int count = 0;
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  final ratings = snap.data!.docs
                      .map((d) => (d['rating'] as num?)?.toDouble() ?? 0)
                      .toList();
                  count = ratings.length;
                  if (ratings.isNotEmpty) {
                    avg = ratings.reduce((a, b) => a + b) / ratings.length;
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      title: 'Avg Rating',
                      value: count == 0 ? '—' : avg.toStringAsFixed(2),
                      footer: count == 0 ? 'No reviews' : '$count reviews',
                      color: Colors.amber,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: favoritesRef.snapshots(),
                      builder: (_, favSnap) {
                        final favCount = favSnap.hasData
                            ? favSnap.data!.docs.length
                            : 0;
                        return _StatCard(
                          title: 'Favorites',
                          value: favCount.toString(),
                          footer: 'All-time',
                          color: Colors.pinkAccent,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ======== Visitors line chart ========
            StreamBuilder<QuerySnapshot>(
              stream: dailyMetricsRef.snapshots(),
              builder: (context, snap) {
                final data = <_DailyPoint>[];
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  for (final d in snap.data!.docs) {
                    final id = d.id; // YYYY-MM-DD
                    final visitors = (d['visitors'] as num?)?.toDouble() ?? 0;
                    data.add(_DailyPoint(label: id, value: visitors));
                  }
                } else {
                  // demo filler (7 days)
                  data.addAll([
                    _DailyPoint(label: '2025-01-01', value: 40),
                    _DailyPoint(label: '2025-01-02', value: 55),
                    _DailyPoint(label: '2025-01-03', value: 30),
                    _DailyPoint(label: '2025-01-04', value: 78),
                    _DailyPoint(label: '2025-01-05', value: 65),
                    _DailyPoint(label: '2025-01-06', value: 72),
                    _DailyPoint(label: '2025-01-07', value: 90),
                  ]);
                }

                return _LineChartCard(
                  title: 'Daily Visitors (last ${data.length} days)',
                  points: data,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 16),

            // ======== Favorites per day (bar) ========
            StreamBuilder<QuerySnapshot>(
              stream: dailyMetricsRef.snapshots(),
              builder: (context, snap) {
                final data = <_DailyPoint>[];
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  for (final d in snap.data!.docs) {
                    final id = d.id; // YYYY-MM-DD
                    final favs =
                        (d['favorites_added'] as num?)?.toDouble() ?? 0;
                    data.add(_DailyPoint(label: id, value: favs));
                  }
                } else {
                  // demo filler (7 days)
                  data.addAll([
                    _DailyPoint(label: '2025-01-01', value: 6),
                    _DailyPoint(label: '2025-01-02', value: 3),
                    _DailyPoint(label: '2025-01-03', value: 4),
                    _DailyPoint(label: '2025-01-04', value: 7),
                    _DailyPoint(label: '2025-01-05', value: 5),
                    _DailyPoint(label: '2025-01-06', value: 6),
                    _DailyPoint(label: '2025-01-07', value: 8),
                  ]);
                }

                return _BarChartCard(
                  title: 'Favorites Added Per Day',
                  bars: data,
                  color: Colors.pinkAccent,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Helpers & widgets ---------- */

class _DailyPoint {
  final String label; // e.g., '2025-01-01'
  final double value;
  _DailyPoint({required this.label, required this.value});
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String footer;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.footer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(footer, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final String title;
  final List<_DailyPoint> points;
  final Color color;

  const _LineChartCard({
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length)
                            return const SizedBox.shrink();
                          // Show short day indices or last 6 chars of date
                          final label = points[idx].label.length >= 6
                              ? points[idx].label.substring(
                                  points[idx].label.length - 5,
                                )
                              : points[idx].label;
                          return Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval:
                            (points
                                        .map((e) => e.value)
                                        .fold<double>(
                                          0,
                                          (p, c) => c > p ? c : p,
                                        ) /
                                    4)
                                .clamp(1, 999)
                                .toDouble(),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      spots: spots,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final List<_DailyPoint> bars;
  final Color color;

  const _BarChartCard({
    required this.title,
    required this.bars,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < bars.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: bars[i].value,
              width: 14,
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= bars.length)
                            return const SizedBox.shrink();
                          final label = bars[i].label.length >= 5
                              ? bars[i].label.substring(
                                  bars[i].label.length - 5,
                                )
                              : bars[i].label;
                          return Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
