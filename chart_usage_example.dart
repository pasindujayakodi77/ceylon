// Example of using BusinessAnalyticsService with FL Chart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:ceylon/features/business/data/business_models.dart';

class BusinessStatsChart extends StatelessWidget {
  final String businessId;
  
  const BusinessStatsChart({super.key, required this.businessId});
  
  @override
  Widget build(BuildContext context) {
    final analyticsService = BusinessAnalyticsService.shared;
    
    return StreamBuilder<List<DailyStat>>(
      stream: analyticsService.streamDailyStats(businessId, days: 30),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data!;
        
        // Create line chart data
        final spots = stats.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.views.toDouble());
        }).toList();
        
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusinessRatingPieChart extends StatelessWidget {
  final String businessId;
  
  const BusinessRatingPieChart({super.key, required this.businessId});
  
  @override
  Widget build(BuildContext context) {
    final analyticsService = BusinessAnalyticsService.shared;
    
    return FutureBuilder<Map<int, int>>(
      future: analyticsService.ratingDistribution(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final distribution = snapshot.data!;
        final totalRatings = distribution.values.fold<int>(0, (total, count) => total + count);
        
        if (totalRatings == 0) {
          return const Center(child: Text('No ratings yet'));
        }
        
        // Create pie chart sections
        final sections = distribution.entries.map((entry) {
          final rating = entry.key;
          final count = entry.value;
          final percentage = count / totalRatings;
          
          return PieChartSectionData(
            value: percentage * 100,
            title: '$rating★',
            radius: 100,
            color: Colors.amber.shade700,
          );
        }).toList();
        
        return PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
          ),
        );
      },
    );
  }
}
