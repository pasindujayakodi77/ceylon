// FILE: lib/features/currency/presentation/screens/currency_and_tips_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:ceylon/features/currency/data/local_rates_repository.dart';
import 'package:ceylon/features/currency/data/local_tipping_repository.dart';

/// Beautiful, offline-first Currency Converter + Tipping Guide.
/// - Two tabs (Converter / Tips)
/// - Quick amount chips, quick currency chips
/// - Live result, swap button, copy result
/// - Tipping calculator with bands (Low/Std/High), per-service guidance
class CurrencyAndTipsScreen extends StatefulWidget {
  const CurrencyAndTipsScreen({super.key});

  @override
  State<CurrencyAndTipsScreen> createState() => _CurrencyAndTipsScreenState();
}

class _CurrencyAndTipsScreenState extends State<CurrencyAndTipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  FxRates? _rates;
  TippingGuide? _tips;

  final _amountCtrl = TextEditingController(text: '1000');
  String _from = 'LKR';
  String _to = 'USD';

  // Tip calc inputs
  final _billCtrl = TextEditingController(text: '5000'); // in local currency
  String _tipBand = 'std'; // low | std | high
  int _split = 1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amountCtrl.dispose();
    _billCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rates = await LocalRatesRepository.instance.load();
    final tips = await LocalTippingRepository.instance.loadForCountry(
      countryCode: 'LK',
    );
    setState(() {
      _rates = rates;
      _tips = tips;
      // Prefer to default "from" to base, "to" to USD if present
      _from = rates.base;
      _to = rates.rates.keys.contains('USD') ? 'USD' : rates.rates.keys.first;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  double? _convert() {
    final r = _rates;
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (r == null || amt == null) return null;
    return r.convert(amt, _from, _to);
  }

  double _tipPct() {
    final t = _tips;
    if (t == null) return 0;
    switch (_tipBand) {
      case 'low':
        return t.restaurants.lowPct;
      case 'high':
        return t.restaurants.highPct;
      case 'std':
      default:
        return t.restaurants.stdPct;
    }
  }

  String _fmt(String code, double? v) {
    if (v == null) return '—';
    final nf = NumberFormat.currency(
      symbol: _sym(code),
      decimalDigits: _dec(code),
    );
    return nf.format(v);
  }

  String _sym(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'LKR':
        return 'රු';
      case 'AUD':
        return 'A\$';
      case 'RUB':
        return '₽';
      case 'MVR':
        return 'Rf';
      default:
        return '$code ';
    }
  }

  int _dec(String code) {
    switch (code.toUpperCase()) {
      case 'JPY':
      case 'LKR': // often shown with 2 decimals anyway; keep 2 for consistency
        return 2;
      default:
        return 2;
    }
  }

  List<String> get _supported {
    final list = _rates?.rates.keys.toList() ?? ['LKR', 'USD'];
    list.sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final r = _rates;
    final asOf = r?.asOf;
    final result = _convert();

    return Scaffold(
      appBar: AppBar(
        title: const Text('💱 Currency & Tips'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Converter', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'Tips', icon: Icon(Icons.room_service)),
          ],
        ),
      ),
      body: r == null || _tips == null
          ? const _Loading()
          : TabBarView(
              controller: _tabs,
              children: [_buildConverter(asOf, result), _buildTips()],
            ),
    );
  }

  // ---------------- Converter Tab ----------------

  Widget _buildConverter(DateTime? asOf, double? result) {
    final base = _rates!.base;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Panel(
          title: 'Amount',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter amount',
                    prefixText: '${_sym(_from)} ',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              _CurrencyPicker(
                value: _from,
                items: _supported,
                onChanged: (v) => setState(() => _from = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Panel(
                title: 'Convert to',
                child: _CurrencyPicker(
                  value: _to,
                  items: _supported,
                  onChanged: (v) => setState(() => _to = v),
                  dense: true,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Swap',
              onPressed: _swap,
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final v in ['100', '500', '1000', '5000', '10000'])
              ActionChip(
                label: Text(v),
                onPressed: () {
                  _amountCtrl.text = v;
                  setState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Result',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _fmt(_to, result),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: result == null
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${_amountCtrl.text} $_from ≈ ${_fmt(_to, result)}',
                          ),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        }
                      },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _InfoBar(
          text:
              'Offline rates. Base: $base • As of: ${asOf != null ? DateFormat.yMMMd().add_Hm().format(asOf) : '—'}',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 18),

        Text(
          'Quick currencies',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quick in ['USD', 'EUR', 'GBP', 'INR', 'AUD'])
              ChoiceChip(
                label: Text(quick),
                selected: _to == quick,
                onSelected: (_) => setState(() => _to = quick),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------- Tips Tab ----------------

  Widget _buildTips() {
    final t = _tips!;
    final nfLocal = NumberFormat.currency(
      symbol: _sym(t.currencyCode),
      decimalDigits: _dec(t.currencyCode),
    );
    final bill =
        double.tryParse(_billCtrl.text.replaceAll(',', '').trim()) ?? 0.0;

    double pct = _tipPct();
    final tipAmt = bill * (pct / 100.0);
    final perPerson = _split <= 1 ? null : (bill + tipAmt) / _split;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Panel(
          title: 'Restaurant bill',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _billCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Bill (${t.currencyCode})',
                  prefixText: '${_sym(t.currencyCode)} ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Low')),
                  ButtonSegment(value: 'std', label: Text('Standard')),
                  ButtonSegment(value: 'high', label: Text('High')),
                ],
                selected: {_tipBand},
                onSelectionChanged: (s) => setState(() => _tipBand = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KV(
                      'Tip (${pct.toStringAsFixed(0)}%)',
                      nfLocal.format(tipAmt),
                    ),
                  ),
                  Expanded(child: _KV('Total', nfLocal.format(bill + tipAmt))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Split'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _split,
                          onChanged: (v) => setState(() => _split = v ?? 1),
                          items: [1, 2, 3, 4, 5, 6, 8]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  if (perPerson != null)
                    Expanded(
                      child: _KV('Per person', nfLocal.format(perPerson)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Service guidance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _GuideTile(
          icon: Icons.restaurant,
          title: 'Restaurants',
          subtitle:
              'Typical ${t.restaurants.lowPct.toStringAsFixed(0)}–${t.restaurants.highPct.toStringAsFixed(0)}% • Standard ${t.restaurants.stdPct.toStringAsFixed(0)}%',
        ),
        _GuideTile(
          icon: Icons.local_taxi,
          title: 'Taxis',
          subtitle:
              'Round up or ${t.taxis.stdPct.toStringAsFixed(0)}% if meter/fare shown',
        ),
        _GuideTile(
          icon: Icons.luggage,
          title: 'Porter',
          subtitle:
              '${_sym(t.currencyCode)} ${t.porter.amount.toStringAsFixed(0)} per ${t.porter.unit}',
        ),
        _GuideTile(
          icon: Icons.hotel,
          title: 'Housekeeping',
          subtitle:
              '${_sym(t.currencyCode)} ${t.housekeeping.amount.toStringAsFixed(0)} per ${t.housekeeping.unit}',
        ),
        _GuideTile(
          icon: Icons.hiking,
          title: 'Private guide',
          subtitle:
              '${_sym(t.currencyCode)} ${t.guide.amount.toStringAsFixed(0)} per ${t.guide.unit}',
        ),
        const SizedBox(height: 16),
        _InfoBar(
          text:
              'Guidance only. Tip according to service quality and local norms.',
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

// ---------------- Small UI helpers ----------------

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool dense;
  const _CurrencyPicker({
    required this.value,
    required this.items,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final input = InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: dense,
          isExpanded: true,
          onChanged: (v) => v == null ? null : onChanged(v),
          items: items
              .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
              .toList(),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == double.infinity) {
          return SizedBox(width: 120, child: input);
        }
        return input;
      },
    );
  }
}

class _InfoBar extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoBar({required this.text, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(v, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _GuideTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(radius: 18, child: Icon(icon, size: 20)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
