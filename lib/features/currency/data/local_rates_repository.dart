import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class LocalRatesRepository {
  static const _assetPath = 'assets/json/currency_rates.json';
  static const _prefsFrom = 'currency_from';
  static const _prefsTo = 'currency_to';

  Map<String, double>? _rates; // code -> LKR per 1 unit
  String _base = 'LKR';

  Future<void> load() async {
    if (_rates != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _base = data['base'] as String? ?? 'LKR';
    final r = (data['rates'] as Map<String, dynamic>);
    _rates = r.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  List<String> get supportedCodes {
    final r = _rates ?? {};
    final list = r.keys.toList()..sort();
    return list;
  }

  /// Convert amount from [from] to [to] using base LKR mapping.
  /// rates map: code -> LKR per unit; so:
  ///   amount(from) * (LKR/from) = LKR
  ///   LKR / (LKR/to) = amount(to)
  double convert(String from, String to, double amount) {
    if (_rates == null) throw StateError('Rates not loaded');
    if (!_rates!.containsKey(from) || !_rates!.containsKey(to)) return 0.0;

    final lkrPerFrom = _rates![from]!;
    final lkrPerTo = _rates![to]!;
    final inLKR = amount * lkrPerFrom;
    final out = inLKR / lkrPerTo;
    return out;
  }

  Future<void> saveLastSelection({
    required String from,
    required String to,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefsFrom, from);
    await sp.setString(_prefsTo, to);
  }

  Future<(String from, String to)> loadLastSelection() async {
    final sp = await SharedPreferences.getInstance();
    final from = sp.getString(_prefsFrom) ?? 'USD';
    final to = sp.getString(_prefsTo) ?? 'LKR';
    return (from, to);
  }
}
