// FILE: lib/features/business/presentation/screens/business_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:ceylon/features/business/presentation/cubit/business_dashboard_cubit.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';

class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessDashboardCubit(
        repository: BusinessRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
      )..loadForOwner(FirebaseAuth.instance.currentUser?.uid ?? ''),
      child: const _AnalyticsBody(),
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  const _AnalyticsBody();

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  final _analyticsService = BusinessAnalyticsService.shared;
  int _selectedTimeframeIndex = 1; // Default to 30 days
  bool _isLoading = false;
  bool _showBookings = true;
  bool _showViews = true;

  // Available timeframes in days
  final List<int> _timeframes = [7, 30, 90];

  // Widget classes for summary cards and chart legends
  Widget _summaryCard({
    required String title,
    required dynamic value,
    required IconData icon,
    bool isRating = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isRating
                  ? (value as double).toStringAsFixed(1)
                  : value.toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (isRating)
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < (value as double).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegendItem({
    required Color color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withAlpha((0.3 * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(String businessId) async {
    setState(() => _isLoading = true);

    try {
      final csvData = await _analyticsService.generateCsvExport(
        businessId,
        days: _timeframes[_selectedTimeframeIndex],
      );

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/analytics_export_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported to: $path'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh of the dashboard data
          final cubit = context.read<BusinessDashboardCubit>();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await cubit.loadForOwner(userId);
          }
        },
        child: BlocBuilder<BusinessDashboardCubit, BusinessDashboardState>(
          builder: (context, state) {
            if (state is BusinessDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BusinessDashboardError) {
              return Center(child: Text(state.message));
            }

            if (state is BusinessDashboardData) {
              final businessId = state.business.id;
              return _buildAnalyticsContent(businessId);
            }

            return const Center(
              child: Text('No business found for this account.'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(String businessId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTimeframeSelector(),
        const SizedBox(height: 16),
        _buildSummaryCards(businessId),
        const SizedBox(height: 24),
        _buildDailyStatsChart(businessId),
        const SizedBox(height: 24),
        _buildRatingDistributionChart(businessId),
        const SizedBox(height: 16),
        _buildExportButton(businessId),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment<int>(value: 0, label: const Text('7 Days')),
        ButtonSegment<int>(value: 1, label: const Text('30 Days')),
        ButtonSegment<int>(value: 2, label: const Text('90 Days')),
      ],
      selected: {_selectedTimeframeIndex},
      onSelectionChanged: (Set<int> selection) {
        setState(() {
          _selectedTimeframeIndex = selection.first;
        });
      },
    );
  }

  Widget _buildSummaryCards(String businessId) {
    final days = _timeframes[_selectedTimeframeIndex];

    return FutureBuilder<Map<String, num>>(
      future: _analyticsService
          .streamDailyStats(businessId, days: days)
          .first
          .then((stats) => _analyticsService.computeSummary(stats, businessId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final summary = snapshot.data!;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Views',
                    value: summary['totalViews']?.toInt() ?? 0,
                    icon: Icons.visibility,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    title: 'Bookings',
                    value: summary['totalBookings']?.toInt() ?? 0,
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Rating',
                    value: summary['avgRating']?.toDouble() ?? 0.0,
                    isRating: true,
                    icon: Icons.star,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    title: 'Reviews',
                    value: summary['reviewCount']?.toInt() ?? 0,
                    icon: Icons.rate_review,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyStatsChart(String businessId) {
    final days = _timeframes[_selectedTimeframeIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chartLegendItem(
                  color: Colors.blue,
                  label: 'Views',
                  isSelected: _showViews,
                  onTap: () => setState(() => _showViews = !_showViews),
                ),
                const SizedBox(width: 16),
                _chartLegendItem(
                  color: Colors.green,
                  label: 'Bookings',
                  isSelected: _showBookings,
                  onTap: () => setState(() => _showBookings = !_showBookings),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.wait([
                  if (_showViews)
                    _analyticsService
                        .getViewsChartData(businessId, days: days)
                        .then(
                          (data) => {
                            'data': data,
                            'color': Colors.blue,
                            'name': 'Views',
                          },
                        ),
                  if (_showBookings)
                    _analyticsService
                        .getBookingsChartData(businessId, days: days)
                        .then(
                          (data) => {
                            'data': data,
                            'color': Colors.green,
                            'name': 'Bookings',
                          },
                        ),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final seriesData = snapshot.data!;
                  if (seriesData.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  return _buildLineChart(seriesData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> seriesData) {
    // Get all data entries
    final allEntries = <MapEntry<String, int>>[];
    for (final series in seriesData) {
      allEntries.addAll(series['data'] as List<MapEntry<String, int>>);
    }

    // Find max value for Y-axis scaling
    final maxValue = allEntries.fold<int>(
      1, // Default to 1 to avoid division by zero
      (max, entry) => max > entry.value ? max : entry.value,
    );

    // Create line chart series
    final lineBarsData = <LineChartBarData>[];
    for (final series in seriesData) {
      final entries = series['data'] as List<MapEntry<String, int>>;
      final color = series['color'] as Color;

      if (entries.isNotEmpty) {
        // Create spots from data entries
        final spots = entries.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.value.toDouble());
        }).toList();

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: entries.length < 15,
            ), // Show dots only for smaller datasets
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha((0.2 * 255).round()),
            ),
          ),
        );
      }
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: max(1, maxValue / 5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Show only first and last date to avoid crowding
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                // Show first, middle, and last labels only
                final midPoint = (meta.max / 2).round();
                if (value == 0 || value == meta.max || value == midPoint) {
                  try {
                    final entries =
                        (seriesData.first['data']
                            as List<MapEntry<String, int>>);
                    final dateString = entries[value.toInt()].key;
                    // Show short date format
                    final parts = dateString.split('-');
                    if (parts.length == 3) {
                      return Text(
                        '${parts[1]}/${parts[2]}',
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                  } catch (_) {}
                }
                return const SizedBox();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % max(1, (meta.max / 4).round()) == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Widget _buildRatingDistributionChart(String businessId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: FutureBuilder<Map<int, int>>(
                future: _analyticsService.ratingDistribution(businessId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final distribution = snapshot.data!;
                  final totalRatings = distribution.values.fold<int>(
                    0,
                    (acc, val) => acc + val,
                  );

                  if (totalRatings == 0) {
                    return const Center(child: Text('No ratings yet'));
                  }

                  // Find the maximum count for scaling
                  final maxCount = distribution.values.fold<int>(
                    1, // Default to 1 to avoid division by zero
                    (curMax, val) => curMax > val ? curMax : val,
                  );

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxCount.toDouble(),
                      barGroups: [5, 4, 3, 2, 1].map((rating) {
                        final count = distribution[rating] ?? 0;
                        return BarChartGroupData(
                          x: rating,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              color: _getRatingColor(rating),
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                ],
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 ||
                                  value == maxCount / 2 ||
                                  value == maxCount) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxCount / 4,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExportButton(String businessId) {
    return Center(
      child: FilledButton.icon(
        onPressed: _isLoading ? null : () => _exportCsv(businessId),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.file_download),
        label: const Text('Export CSV'),
      ),
    );
  }
}
