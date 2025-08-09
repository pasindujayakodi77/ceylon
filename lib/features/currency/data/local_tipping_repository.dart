import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TippingCountry {
  final String code; // e.g., 'LK'
  final String name; // 'Sri Lanka'
  final String currency; // 'LKR'
  final String general;
  final Map<String, String> services; // restaurant/cafe/hotel/tuktuk_taxi/guide

  TippingCountry({
    required this.code,
    required this.name,
    required this.currency,
    required this.general,
    required this.services,
  });
}

class LocalTippingRepository {
  static const _assetPath = 'assets/json/tipping_guide.json';
  Map<String, TippingCountry>? _cache;

  Future<void> load() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final countries = data['countries'] as Map<String, dynamic>;

    _cache = {};
    countries.forEach((code, value) {
      final v = value as Map<String, dynamic>;
      _cache![code] = TippingCountry(
        code: code,
        name: v['name'] as String,
        currency: v['currency'] as String,
        general: v['general'] as String? ?? '',
        services: (v['services'] as Map<String, dynamic>).map(
          (k, vv) => MapEntry(k, vv.toString()),
        ),
      );
    });
  }

  List<TippingCountry> all() {
    final list = _cache!.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  TippingCountry? byCode(String code) => _cache![code];

  /// Helper to map a currency code to a default country (for quick sync with converter)
  String defaultCountryForCurrency(String currency) {
    switch (currency) {
      case 'LKR':
        return 'LK';
      case 'USD':
        return 'US';
      case 'GBP':
        return 'GB';
      case 'EUR':
        return 'DE'; // could be DE/FR/NL — pick DE as default
      case 'INR':
        return 'IN';
      case 'AUD':
        return 'AU';
      case 'MVR':
        return 'MV';
      case 'RUB':
        return 'RU';
      default:
        return 'LK';
    }
  }
}
