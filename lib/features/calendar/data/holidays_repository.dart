// FILE: lib/features/calendar/data/holidays_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'holiday.dart';

class HolidaysRepository {
  /// Load holidays from local JSON asset
  Future<List<Holiday>> loadHolidaysFromAsset([
    String path = 'assets/json/holidays_lk.json',
  ]) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonData = json.decode(jsonString);

      return jsonData
          .map((item) => Holiday.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load holidays from asset: $e');
    }
  }

  /// Group holidays by day (truncated to yyyy-mm-dd)
  Map<DateTime, List<Holiday>> groupByDay(List<Holiday> holidays) {
    final Map<DateTime, List<Holiday>> grouped = {};

    for (final holiday in holidays) {
      // Truncate to date only (remove time component)
      final date = DateTime(
        holiday.date.year,
        holiday.date.month,
        holiday.date.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(holiday);
      } else {
        grouped[date] = [holiday];
      }
    }

    return grouped;
  }

  /// Get holidays for a specific month
  List<Holiday> getHolidaysForMonth(List<Holiday> holidays, DateTime month) {
    return holidays.where((holiday) {
      return holiday.date.year == month.year &&
          holiday.date.month == month.month;
    }).toList();
  }

  /// Get holidays for a specific year
  List<Holiday> getHolidaysForYear(List<Holiday> holidays, int year) {
    return holidays.where((holiday) => holiday.date.year == year).toList();
  }

  /// Get upcoming holidays from current date
  List<Holiday> getUpcomingHolidays(List<Holiday> holidays, {int limit = 5}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return holidays
        .where((holiday) {
          final holidayDate = DateTime(
            holiday.date.year,
            holiday.date.month,
            holiday.date.day,
          );
          return holidayDate.isAfter(today) ||
              holidayDate.isAtSameMomentAs(today);
        })
        .take(limit)
        .toList();
  }

  /// Check if a specific date is a holiday
  bool isHoliday(List<Holiday> holidays, DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    return holidays.any((holiday) {
      final holidayDate = DateTime(
        holiday.date.year,
        holiday.date.month,
        holiday.date.day,
      );
      return holidayDate.isAtSameMomentAs(checkDate);
    });
  }

  /// Get holiday for a specific date (if any)
  Holiday? getHolidayForDate(List<Holiday> holidays, DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    try {
      return holidays.firstWhere((holiday) {
        final holidayDate = DateTime(
          holiday.date.year,
          holiday.date.month,
          holiday.date.day,
        );
        return holidayDate.isAtSameMomentAs(checkDate);
      });
    } catch (e) {
      return null;
    }
  }
}
