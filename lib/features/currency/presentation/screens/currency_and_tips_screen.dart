import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ceylon/features/currency/data/local_rates_repository.dart';
import 'package:ceylon/features/currency/data/local_tipping_repository.dart';

class CurrencyAndTipsScreen extends StatefulWidget {
  const CurrencyAndTipsScreen({super.key});

  @override
  State<CurrencyAndTipsScreen> createState() => _CurrencyAndTipsScreenState();
}

class _CurrencyAndTipsScreenState extends State<CurrencyAndTipsScreen> {
  final _ratesRepo = LocalRatesRepository();
  final _tipsRepo = LocalTippingRepository();

  final _amountCtrl = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'LKR';
  double _result = 0.0;

  // tipping
  String _countryCode = 'LK';
  TippingCountry? _country;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _ratesRepo.load();
    await _tipsRepo.load();

    final (lastFrom, lastTo) = await _ratesRepo.loadLastSelection();
    _from = lastFrom;
    _to = lastTo;

    // default country aligns to "to" currency (e.g., converting to LKR → Sri Lanka)
    _countryCode = _tipsRepo.defaultCountryForCurrency(_to);
    _country = _tipsRepo.byCode(_countryCode);

    _recalc();
    setState(() => _loading = false);
  }

  void _recalc() {
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final out = _ratesRepo.convert(_from, _to, amt);
    setState(() => _result = out);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _symbol(String code) {
    switch (code) {
      case 'LKR':
        return 'Rs';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'AUD':
        return 'A\$';
      case 'MVR':
        return 'Rf';
      case 'RUB':
        return '₽';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final codes = _ratesRepo.supportedCodes;
    final countries = _tipsRepo.all();

    return Scaffold(
      appBar: AppBar(title: const Text('💱 Currency & Tipping')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Converter card =====
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Currency Converter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _from,
                          decoration: const InputDecoration(labelText: 'From'),
                          items: codes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('$c (${_symbol(c)})'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _from = v!);
                            _recalc();
                            _ratesRepo.saveLastSelection(from: _from, to: _to);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final tmp = _from;
                            _from = _to;
                            _to = tmp;
                            // also flip country to match the new "to"
                            _countryCode = _tipsRepo.defaultCountryForCurrency(
                              _to,
                            );
                            _country = _tipsRepo.byCode(_countryCode);
                          });
                          _recalc();
                          _ratesRepo.saveLastSelection(from: _from, to: _to);
                        },
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _to,
                          decoration: const InputDecoration(labelText: 'To'),
                          items: codes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('$c (${_symbol(c)})'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _to = v!;
                              _countryCode = _tipsRepo
                                  .defaultCountryForCurrency(_to);
                              _country = _tipsRepo.byCode(_countryCode);
                            });
                            _recalc();
                            _ratesRepo.saveLastSelection(from: _from, to: _to);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => _recalc(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Result',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Text(
                          '${_symbol(_to)} ${_result.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Offline rates as of 2025‑08‑01. Edit assets/json/currency_rates.json to update.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== Tipping card =====
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipping Guide',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _countryCode,
                    decoration: const InputDecoration(labelText: 'Country'),
                    items: countries
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.code,
                            child: Text('${c.name}  (${c.currency})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _countryCode = v!;
                        _country = _tipsRepo.byCode(_countryCode);
                        // Also align "to" currency if user wants (optional). We keep it independent here.
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_country != null) ...[
                    Text(_country!.general),
                    const SizedBox(height: 10),
                    _TipRow(
                      label: 'Restaurant',
                      text: _country!.services['restaurant'] ?? '-',
                    ),
                    _TipRow(
                      label: 'Cafe',
                      text: _country!.services['cafe'] ?? '-',
                    ),
                    _TipRow(
                      label: 'Hotel',
                      text: _country!.services['hotel'] ?? '-',
                    ),
                    _TipRow(
                      label: 'Taxi/Tuk‑tuk',
                      text: _country!.services['tuktuk_taxi'] ?? '-',
                    ),
                    _TipRow(
                      label: 'Guide',
                      text: _country!.services['guide'] ?? '-',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String label;
  final String text;
  const _TipRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
