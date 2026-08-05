import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Gold and silver rates, per gram, in the local currency.
///
/// WHY THERE IS NO LIVE API CALL IN HERE YET
///
/// A rate fetched from an endpoint that has not been tested is worse than no
/// endpoint at all: it fails at the exact moment someone is working out what
/// they owe, and it fails quietly. Zakat is a financial obligation, so a wrong
/// or stale number is not a cosmetic bug.
///
/// So this stores the rate the user enters, caches it with the date it was
/// entered, and says plainly how old it is. That works offline, needs no API
/// key, no subscription and no new package.
///
/// TO ADD A LIVE PROVIDER LATER: implement [fetchLive] and nothing else has to
/// change. Keep the manual path — it is the fallback for no signal, a dead
/// provider, or an expired key, and it is what makes the calculator dependable.
class MetalRates {
  const MetalRates({
    required this.goldPerGram,
    required this.silverPerGram,
    required this.updated,
    required this.source,
  });

  /// Price of ONE GRAM of pure (24k / 999) metal.
  final double goldPerGram;
  final double silverPerGram;

  final DateTime updated;

  /// 'manual' or 'live'. Shown to the user, because they should know whether
  /// the number came from them or from a server.
  final String source;

  bool get isStale => DateTime.now().difference(updated).inHours >= 24;

  int get ageInDays => DateTime.now().difference(updated).inDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'gold': goldPerGram,
        'silver': silverPerGram,
        'updated': updated.millisecondsSinceEpoch,
        'source': source,
      };

  static MetalRates? fromJson(Map<String, dynamic> j) {
    try {
      return MetalRates(
        goldPerGram: (j['gold'] as num).toDouble(),
        silverPerGram: (j['silver'] as num).toDouble(),
        updated: DateTime.fromMillisecondsSinceEpoch(j['updated'] as int),
        source: j['source'] as String? ?? 'manual',
      );
    } catch (_) {
      return null;
    }
  }
}

class MetalRateService {
  MetalRateService._();

  static const _key = 'metal_rates_v1';

  static Future<MetalRates?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return MetalRates.fromJson(Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(MetalRates rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(rates.toJson()));
    } catch (_) {}
  }

  /// Fetches today's rates from a provider. NOT IMPLEMENTED.
  ///
  /// Returns null so callers fall back to the stored rate. When you have chosen
  /// a provider, implement this to return one gram of PURE metal in the local
  /// currency, cache the result with source 'live', and only call it once a day
  /// — [MetalRates.isStale] already tells you when that is due.
  static Future<MetalRates?> fetchLive() async => null;
}

/// Gold purity by karat. 24k is pure; the rest are fractions of it.
enum GoldKarat { k24, k22, k21, k18 }

extension GoldKaratX on GoldKarat {
  /// Fraction of pure gold. A 22k gram is 0.9167 of a pure gram, which is why
  /// jewellery is never worth the 24k rate.
  double get purity {
    switch (this) {
      case GoldKarat.k24:
        return 1.0;
      case GoldKarat.k22:
        return 22 / 24;
      case GoldKarat.k21:
        return 21 / 24;
      case GoldKarat.k18:
        return 18 / 24;
    }
  }

  String get label {
    switch (this) {
      case GoldKarat.k24:
        return '24K (999)';
      case GoldKarat.k22:
        return '22K (916)';
      case GoldKarat.k21:
        return '21K (875)';
      case GoldKarat.k18:
        return '18K (750)';
    }
  }
}

/// Silver purity. NOT karat — karat is a gold measure only, and a jeweller's
/// receipt for silver will say 999, 925 or 900 rather than a karat number.
enum SilverPurity { fine999, sterling925, coin900 }

extension SilverPurityX on SilverPurity {
  double get purity {
    switch (this) {
      case SilverPurity.fine999:
        return 0.999;
      case SilverPurity.sterling925:
        return 0.925;
      case SilverPurity.coin900:
        return 0.900;
    }
  }

  String get label {
    switch (this) {
      case SilverPurity.fine999:
        return '999 (fine)';
      case SilverPurity.sterling925:
        return '925 (sterling)';
      case SilverPurity.coin900:
        return '900';
    }
  }
}

/// Which threshold decides whether zakat is due.
///
/// The two are NOT equivalent in value. Silver's threshold is far lower, so it
/// catches many more people — which is why the choice is a religious one and is
/// left to the user rather than assumed.
enum NisabBasis { silver, gold }

extension NisabBasisX on NisabBasis {
  /// Grams of pure metal. These follow the figures the app owner specified.
  /// Other published figures exist (612.36g silver, 87.48g gold), so if an aalim
  /// asks for those, change them here only.
  double get grams => this == NisabBasis.silver ? 595.0 : 85.0;
}

/// The calculation itself, kept away from the UI so it can be reasoned about
/// and checked on its own.
class ZakatResult {
  const ZakatResult({
    required this.goldValue,
    required this.silverValue,
    required this.cash,
    required this.liabilities,
    required this.netAssets,
    required this.nisabValue,
    required this.isApplicable,
    required this.zakatDue,
  });

  final double goldValue;
  final double silverValue;
  final double cash;
  final double liabilities;
  final double netAssets;
  final double nisabValue;
  final bool isApplicable;

  /// 2.5% of net assets, or zero when below nisab.
  final double zakatDue;
}

class ZakatCalculator {
  ZakatCalculator._();

  static const double rate = 0.025; // 2.5%

  static ZakatResult compute({
    required MetalRates rates,
    required NisabBasis basis,
    double goldGrams = 0,
    GoldKarat karat = GoldKarat.k22,
    double silverGrams = 0,
    SilverPurity silverPurity = SilverPurity.fine999,
    double cash = 0,
    double liabilities = 0,
  }) {
    // Purity matters. 100g of 22k gold is 91.67g of gold, and valuing it at the
    // pure rate would overstate what is owed.
    final double goldValue = goldGrams * karat.purity * rates.goldPerGram;
    final double silverValue =
        silverGrams * silverPurity.purity * rates.silverPerGram;

    final double gross = goldValue + silverValue + cash;
    final double net = gross - liabilities;

    final double perGram =
        basis == NisabBasis.silver ? rates.silverPerGram : rates.goldPerGram;
    final double nisabValue = basis.grams * perGram;

    // Below nisab, nothing is owed — not a smaller amount.
    final bool applicable = net >= nisabValue && net > 0;

    return ZakatResult(
      goldValue: goldValue,
      silverValue: silverValue,
      cash: cash,
      liabilities: liabilities,
      netAssets: net,
      nisabValue: nisabValue,
      isApplicable: applicable,
      zakatDue: applicable ? net * rate : 0,
    );
  }
}
