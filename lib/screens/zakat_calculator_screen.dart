import 'package:flutter/material.dart';

import '../services/app_strings.dart';
import '../services/zakat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  MetalRates? _rates;
  bool _loading = true;

  NisabBasis _basis = NisabBasis.silver;
  GoldKarat _karat = GoldKarat.k22;
  SilverPurity _silverPurity = SilverPurity.fine999;

  final _gold = TextEditingController();
  final _silver = TextEditingController();
  final _cash = TextEditingController();
  final _liabilities = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_gold, _silver, _cash, _liabilities]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    // Try a live provider first; falls back to whatever is stored. fetchLive
    // returns null until a provider is chosen, so today this is always the
    // stored rate.
    final live = await MetalRateService.fetchLive();
    final stored = await MetalRateService.load();
    if (!mounted) return;
    setState(() {
      _rates = live ?? stored;
      _loading = false;
    });
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  ZakatResult? get _result {
    final r = _rates;
    if (r == null) return null;
    return ZakatCalculator.compute(
      rates: r,
      basis: _basis,
      goldGrams: _num(_gold),
      karat: _karat,
      silverGrams: _num(_silver),
      silverPurity: _silverPurity,
      cash: _num(_cash),
      liabilities: _num(_liabilities),
    );
  }

  String _money(double v) {
    // Grouped with commas, two decimals. Deliberately no currency symbol: the
    // rate the user typed is in their own currency and the app has no business
    // guessing which.
    final parts = v.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$whole.${parts[1]}';
  }

  Future<void> _editRates() async {
    final gold = TextEditingController(
        text: _rates == null ? '' : _rates!.goldPerGram.toStringAsFixed(2));
    final silver = TextEditingController(
        text: _rates == null ? '' : _rates!.silverPerGram.toStringAsFixed(2));

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.todaysRates,
            style: AppText.rowTitle.copyWith(color: AppColors.emerald)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gold,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: '${S.goldLabel} \u2014 24K ${S.ratePerGram}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: silver,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: '${S.silverLabel} \u2014 999 ${S.ratePerGram}'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(S.save)),
        ],
      ),
    );

    if (saved != true) return;
    final g = double.tryParse(gold.text.trim());
    final s = double.tryParse(silver.text.trim());
    if (g == null || s == null || g <= 0 || s <= 0) return;

    final r = MetalRates(
      goldPerGram: g,
      silverPerGram: s,
      updated: DateTime.now(),
      source: 'manual',
    );
    await MetalRateService.save(r);
    if (mounted) setState(() => _rates = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.zakatCalculator),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: S.updateRates,
            onPressed: _editRates,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _ratesCard(),
                const SizedBox(height: 18),

                SectionRule(label: S.nisabBasis, trailingDiamond: true),
                const SizedBox(height: 4),
                // Two options, chosen by the user. They are not equivalent: the
                // silver threshold is far lower, so it catches many more
                // people. That is a religious choice, not a default the app
                // should make silently.
                RadioListTile<NisabBasis>(
                  value: NisabBasis.silver,
                  groupValue: _basis,
                  activeColor: AppColors.emerald,
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.silverNisab, style: AppText.body),
                  onChanged: (v) => setState(() => _basis = v!),
                ),
                RadioListTile<NisabBasis>(
                  value: NisabBasis.gold,
                  groupValue: _basis,
                  activeColor: AppColors.emerald,
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.goldNisab, style: AppText.body),
                  onChanged: (v) => setState(() => _basis = v!),
                ),

                const SizedBox(height: 14),
                SectionRule(label: S.goldLabel, trailingDiamond: true),
                const SizedBox(height: 10),
                _amountField(_gold, S.gramsLabel),
                const SizedBox(height: 10),
                DropdownButtonFormField<GoldKarat>(
                  value: _karat,
                  decoration: InputDecoration(labelText: S.karatLabel),
                  items: GoldKarat.values
                      .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k.label, style: AppText.body)))
                      .toList(),
                  onChanged: (v) => setState(() => _karat = v!),
                ),

                const SizedBox(height: 18),
                SectionRule(label: S.silverLabel, trailingDiamond: true),
                const SizedBox(height: 10),
                _amountField(_silver, S.gramsLabel),
                const SizedBox(height: 10),
                // Purity, not karat. Karat is a gold measure; a silver receipt
                // says 999, 925 or 900.
                DropdownButtonFormField<SilverPurity>(
                  value: _silverPurity,
                  decoration: InputDecoration(labelText: S.purityLabel),
                  items: SilverPurity.values
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.label, style: AppText.body)))
                      .toList(),
                  onChanged: (v) => setState(() => _silverPurity = v!),
                ),

                const SizedBox(height: 18),
                SectionRule(label: S.cashLabel, trailingDiamond: true),
                const SizedBox(height: 10),
                _amountField(_cash, S.cashLabel),
                const SizedBox(height: 10),
                _amountField(_liabilities, S.liabilitiesLabel),

                const SizedBox(height: 22),
                if (r != null) _resultCard(r),

                const SizedBox(height: 16),
                Text(S.zakatDisclaimer,
                    style: AppText.caption.copyWith(color: AppColors.textFaint)),
              ],
            ),
    );
  }

  Widget _amountField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        style: AppText.body.copyWith(color: AppColors.text),
        onChanged: (_) => setState(() {}),
      );

  Widget _ratesCard() {
    final r = _rates;
    if (r == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.gold),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warningFg, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(S.ratesNeeded,
                  style: AppText.caption.copyWith(color: AppColors.warningFg)),
            ),
            TextButton(
                onPressed: _editRates,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.warningFg),
                child: Text(S.updateRates)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: r.isStale ? AppColors.gold : AppColors.goldRule,
            width: r.isStale ? 1.4 : 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(S.todaysRates,
                    style: AppText.rowTitle
                        .copyWith(fontSize: 15, color: AppColors.text)),
              ),
              Text(
                r.ageInDays == 0
                    ? 'today'
                    : '${r.ageInDays}d old',
                style: AppText.caption.copyWith(
                    color: r.isStale ? AppColors.gold : AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${S.goldLabel} 24K: ${_money(r.goldPerGram)} / g',
              style: AppText.caption.copyWith(color: AppColors.textMuted)),
          Text('${S.silverLabel} 999: ${_money(r.silverPerGram)} / g',
              style: AppText.caption.copyWith(color: AppColors.textMuted)),
          if (r.isStale) ...[
            const SizedBox(height: 8),
            Text(S.ratesStale,
                style: AppText.caption.copyWith(color: AppColors.warningFg)),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(ZakatResult r) {
    final bool due = r.isApplicable;
    return Container(
      decoration: BoxDecoration(
        color: due ? AppColors.emerald : AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: due ? AppColors.gold : AppColors.goldRule),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            due
                ? '\u2705 ${S.zakatApplicable}'
                : '\u274C ${S.zakatNotApplicable}',
            style: AppText.rowTitle.copyWith(
                fontSize: 17, color: due ? AppColors.white : AppColors.textMid),
          ),
          const SizedBox(height: 12),
          _line(S.netAssets, _money(r.netAssets), due),
          _line(S.nisabValue, _money(r.nisabValue), due),
          if (due) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.gold.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(S.zakatDue,
                style: AppText.eyebrow.copyWith(color: AppColors.goldPale)),
            Text(_money(r.zakatDue),
                style: AppText.hero
                    .copyWith(fontSize: 34, color: AppColors.white)),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, bool onEmerald) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppText.caption.copyWith(
                      color: onEmerald
                          ? AppColors.onEmeraldMuted
                          : AppColors.textMuted)),
            ),
            Text(value,
                style: AppText.body.copyWith(
                    color: onEmerald ? AppColors.white : AppColors.text)),
          ],
        ),
      );
}
