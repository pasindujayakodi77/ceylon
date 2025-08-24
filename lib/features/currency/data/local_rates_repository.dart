// FILE: lib/features/currency/data/local_rates_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FxRates {
  final String base; // e.g. "LKR"
  final DateTime asOf;
  final Map<String, double> rates; // per 1 base → currency rate

  FxRates({required this.base, required this.asOf, required this.rates});

  double? _rateTo(String code) => rates[code.toUpperCase()];

  /// Convert [amount] from [from] → [to] using this table.
  /// Works even if [from] or [to] are not the base, by pivoting through base.
  double? convert(double amount, String from, String to) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();

    if (f == t) return amount;

    // If converting from base to target
    if (f == base) {
      final rTo = _rateTo(t);
      return rTo == null ? null : amount * rTo;
    }

    // If converting to base from some currency
    if (t == base) {
      final rFrom = _rateTo(f);
      return rFrom == null || rFrom == 0 ? null : amount / rFrom;
    }

    // Otherwise pivot: from → base → to
    final toBase = convert(amount, f, base);
    return toBase == null ? null : convert(toBase, base, t);
  }

  static FxRates fromJson(Map<String, dynamic> m) {
    final base = (m['base'] ?? 'LKR').toString().toUpperCase();
    final asOfStr =
        (m['asOf'] ?? m['as_of'] ?? DateTime.now().toIso8601String())
            .toString();
    final asOf = DateTime.tryParse(asOfStr) ?? DateTime.now();
    final Map<String, double> r = {};
    final raw = (m['rates'] ?? {}) as Map;
    for (final e in raw.entries) {
      final k = e.key.toString().toUpperCase();
      final v = (e.value as num?)?.toDouble();
      if (v != null) r[k] = v;
    }
    // Always include base at 1.0
    r[base] = 1.0;
    return FxRates(base: base, asOf: asOf, rates: r);
  }
}

class LocalRatesRepository {
  LocalRatesRepository._();
  static final LocalRatesRepository instance = LocalRatesRepository._();

  static const _assetPath = 'assets/json/local_rates.json';

  FxRates? _cache;

  /// Loads rates from asset JSON. If missing, falls back to a sane, baked-in table.
  ///
  /// Asset shape:
  /// {
  ///   "base": "LKR",
  ///   "asOf": "2025-01-01T00:00:00Z",
  ///   "rates": { "USD": 0.0031, "EUR": 0.0029, "INR": 0.26, ... }
  /// }
  Future<FxRates> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cache = FxRates.fromJson(json);
      return _cache!;
    } catch (_) {
      // Fallback, offline defaults (adjust anytime)
      _cache = FxRates.fromJson({
        'base': 'LKR',
        'asOf': DateTime.now().toIso8601String(),
        'rates': {
          // Common visitor currencies
          'USD': 0.0033,
          'EUR': 0.0030,
          'GBP': 0.0025,
          'AUD': 0.0049,
          'INR': 0.25,
          'MVR': 0.051,
          'RUB': 0.31,
          'DEMO': 1, // example
          // Keep base at 1.0 (auto-added), add more as needed
        },
      });
      return _cache!;
    }
  }

  /// Convenience list of supported codes (sorted).
  Future<List<String>> supportedCodes() async {
    final r = await load();
    final codes = r.rates.keys.toSet().toList()..sort();
    return codes;
  }
}
