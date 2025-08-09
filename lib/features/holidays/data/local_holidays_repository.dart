import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Holiday {
  final DateTime date;
  final String name;
  final String type; // public/religious/cultural/observance
  Holiday({required this.date, required this.name, required this.type});
}

class CountryHolidays {
  final String code; // LK/US/GB/...
  final String name;
  final List<Holiday> holidays;
  CountryHolidays({
    required this.code,
    required this.name,
    required this.holidays,
  });
}

class LocalHolidaysRepository {
  static const _asset = 'assets/json/holidays.json';

  late final Map<String, CountryHolidays> _countries;
  late final Map<String, Map<String, dynamic>> _types;

  Future<void> load() async {
    final raw = await rootBundle.loadString(_asset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final countries = data['countries'] as Map<String, dynamic>;
    final types = (data['types'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as Map<String, dynamic>),
    );
    _types = types;

    _countries = {};
    countries.forEach((code, value) {
      final v = value as Map<String, dynamic>;
      final name = v['name'] as String;
      final list = (v['holidays'] as List<dynamic>).map((h) {
        final m = h as Map<String, dynamic>;
        return Holiday(
          date: DateTime.parse(m['date'] as String),
          name: m['name'] as String,
          type: m['type'] as String,
        );
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      _countries[code] = CountryHolidays(
        code: code,
        name: name,
        holidays: list,
      );
    });
  }

  List<String> get countryCodes => _countries.keys.toList()..sort();
  CountryHolidays? byCode(String code) => _countries[code];

  Map<String, dynamic>? typeInfo(String type) => _types[type];

  /// Filter by month/year (1-12)
  List<Holiday> filter(String code, int year, int month, {String search = ''}) {
    final c = _countries[code];
    if (c == null) return [];
    final lower = search.trim().toLowerCase();

    return c.holidays.where((h) {
      final okDate = h.date.year == year && h.date.month == month;
      final okSearch = lower.isEmpty || h.name.toLowerCase().contains(lower);
      return okDate && okSearch;
    }).toList();
  }

  /// Next upcoming holidays from today for a country
  List<Holiday> upcoming(String code, {int take = 5}) {
    final c = _countries[code];
    if (c == null) return [];
    final now = DateTime.now();
    final list = c.holidays
        .where((h) => !h.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list.take(take).toList();
  }
}
