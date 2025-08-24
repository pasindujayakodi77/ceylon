// FILE: lib/features/currency/data/local_tipping_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TipBand {
  final double lowPct;
  final double stdPct;
  final double highPct;
  const TipBand({
    required this.lowPct,
    required this.stdPct,
    required this.highPct,
  });
}

class TipFlat {
  final double amount; // per unit in local currency (base), e.g., per bag/night
  final String unit; // "bag", "night", "day", etc.
  const TipFlat({required this.amount, required this.unit});
}

class TippingGuide {
  final String countryCode; // e.g., "LK"
  final String currencyCode; // e.g., "LKR" (base in rates)
  final TipBand restaurants; // % of bill
  final TipBand taxis; // % of fare (many places rounding is used)
  final TipFlat porter; // per bag
  final TipFlat housekeeping; // per night
  final TipFlat guide; // per day (private)
  const TippingGuide({
    required this.countryCode,
    required this.currencyCode,
    required this.restaurants,
    required this.taxis,
    required this.porter,
    required this.housekeeping,
    required this.guide,
  });
}

class LocalTippingRepository {
  LocalTippingRepository._();
  static final LocalTippingRepository instance = LocalTippingRepository._();

  static const _assetPath = 'assets/json/local_tips.json';

  /// Loads from asset; falls back to a reasonable Sri Lanka default.
  ///
  /// Asset shape:
  /// {
  ///   "countryCode": "LK",
  ///   "currencyCode": "LKR",
  ///   "restaurants": { "lowPct": 5, "stdPct": 10, "highPct": 12 },
  ///   "taxis": { "lowPct": 0, "stdPct": 5, "highPct": 10 },
  ///   "porter": { "amount": 200, "unit": "bag" },
  ///   "housekeeping": { "amount": 500, "unit": "night" },
  ///   "guide": { "amount": 5000, "unit": "day" }
  /// }
  Future<TippingGuide> loadForCountry({String countryCode = 'LK'}) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // If your JSON contains multiple countries, pick by code here.
      return _parse(json);
    } catch (_) {
      return TippingGuide(
        countryCode: 'LK',
        currencyCode: 'LKR',
        restaurants: const TipBand(lowPct: 5, stdPct: 10, highPct: 12),
        taxis: const TipBand(lowPct: 0, stdPct: 5, highPct: 10),
        porter: const TipFlat(amount: 200, unit: 'bag'),
        housekeeping: const TipFlat(amount: 500, unit: 'night'),
        guide: const TipFlat(amount: 5000, unit: 'day'),
      );
    }
  }

  TippingGuide _parse(Map<String, dynamic> m) {
    T(double v) => (v).toDouble();
    final r = m['restaurants'] as Map<String, dynamic>;
    final t = m['taxis'] as Map<String, dynamic>;
    final p = m['porter'] as Map<String, dynamic>;
    final h = m['housekeeping'] as Map<String, dynamic>;
    final g = m['guide'] as Map<String, dynamic>;

    return TippingGuide(
      countryCode: (m['countryCode'] ?? 'LK').toString(),
      currencyCode: (m['currencyCode'] ?? 'LKR').toString().toUpperCase(),
      restaurants: TipBand(
        lowPct: T(r['lowPct'] ?? 5),
        stdPct: T(r['stdPct'] ?? 10),
        highPct: T(r['highPct'] ?? 12),
      ),
      taxis: TipBand(
        lowPct: T(t['lowPct'] ?? 0),
        stdPct: T(t['stdPct'] ?? 5),
        highPct: T(t['highPct'] ?? 10),
      ),
      porter: TipFlat(
        amount: T(p['amount'] ?? 200),
        unit: (p['unit'] ?? 'bag').toString(),
      ),
      housekeeping: TipFlat(
        amount: T(h['amount'] ?? 500),
        unit: (h['unit'] ?? 'night').toString(),
      ),
      guide: TipFlat(
        amount: T(g['amount'] ?? 5000),
        unit: (g['unit'] ?? 'day').toString(),
      ),
    );
  }
}
