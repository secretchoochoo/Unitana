import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/data/cities.dart' show kCurrencySymbols;
import 'package:unitana/data/country_currency_map.dart';
import 'package:unitana/theme/dracula_palette.dart';
import 'package:unitana/utils/timezone_utils.dart';

/// Terminal-style readout used by the dashboard pinned mini hero.
///
/// This is intentionally shared so onboarding can preview the *exact* component
/// the dashboard uses, reducing drift and future regressions.
class PinnedMiniHeroReadout extends StatelessWidget {
  final Place primary;
  final Place secondary;
  final DashboardLiveDataController liveData;

  const PinnedMiniHeroReadout({
    super.key,
    required this.primary,
    required this.secondary,
    required this.liveData,
  });

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _hm(DateTime local, {required bool use24h}) {
    final h = local.hour;
    final m = local.minute;
    if (use24h) {
      final hh = h.toString().padLeft(2, '0');
      final mm = m.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final suffix = h >= 12 ? 'PM' : 'AM';
    var hh = h % 12;
    if (hh == 0) hh = 12;
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm $suffix';
  }

  String _dayMonth(DateTime local) {
    final month = (local.month >= 1 && local.month <= 12)
        ? _months[local.month - 1]
        : local.month.toString();
    return '${local.day} $month';
  }

  bool _isImperial(Place p) => p.unitSystem.toLowerCase() == 'imperial';

  String _tempLine(WeatherSnapshot? w, {required Place place}) {
    if (w == null) return '—';
    final c = w.temperatureC.round();
    final f = (c * 9 / 5 + 32).round();
    if (_isImperial(place)) {
      return '$f°F ($c°C)';
    }
    return '$c°C ($f°F)';
  }

  String _windLine(double? kmh, {required Place place}) {
    if (kmh == null) return '—';
    final vKmh = kmh.round();
    if (_isImperial(place)) {
      final mph = (kmh * 0.621371).round();
      return '$mph mph';
    }
    return '$vKmh km/h';
  }

  Color _aqiColor(int? v) {
    if (v == null) return DraculaPalette.comment;
    if (v <= 50) return DraculaPalette.green;
    if (v <= 100) return DraculaPalette.yellow;
    if (v <= 150) return DraculaPalette.orange;
    return DraculaPalette.red;
  }

  String _aqiBandShort(int? v) {
    if (v == null) return '';
    if (v <= 50) return 'Good';
    if (v <= 100) return 'Mod';
    if (v <= 150) return 'USG';
    if (v <= 200) return 'Unh';
    if (v <= 300) return 'VUnh';
    return 'Haz';
  }

  String _pollenBandShort(double? v) {
    if (v == null) return '';
    if (v < 1) return 'Low';
    if (v < 2) return 'Mod';
    if (v < 3) return 'High';
    return 'VHigh';
  }

  String _currencyCodeForPlace(Place p) {
    return currencyCodeForCountryCode(p.countryCode);
  }

  String _currencySymbol(String code) {
    final normalized = code.trim().toUpperCase();
    return kCurrencySymbols[normalized] ?? normalized;
  }

  bool _currencyUsesSuffixSymbol(String code) {
    switch (code.trim().toUpperCase()) {
      case 'AED':
      case 'BHD':
      case 'DZD':
      case 'IQD':
      case 'IRR':
      case 'JOD':
      case 'KWD':
      case 'MAD':
      case 'OMR':
      case 'QAR':
      case 'SAR':
      case 'TND':
        return true;
      default:
        return false;
    }
  }

  String _formattedCurrencyToken(String code, double amount) {
    final symbol = _currencySymbol(code);
    final digits = _fmtCurrencyAmount(amount);
    final token = _currencyUsesSuffixSymbol(code)
        ? '$digits$symbol'
        : '$symbol$digits';
    return '\u2066$token\u2069';
  }

  String _currencyLine() {
    final from = _currencyCodeForPlace(primary);
    final to = _currencyCodeForPlace(secondary);
    final rate = liveData.currencyRate(fromCode: from, toCode: to);

    if (from == to) {
      return '${_formattedCurrencyToken(from, 1)}≈${_formattedCurrencyToken(from, 1)}';
    }

    if (rate == null || rate <= 0) {
      return '${_formattedCurrencyToken(from, 1)}≈\u2066${_currencySymbol(to)}—\u2069';
    }
    final base = _displayBaseAmountForPair(rate);
    final converted = base * rate;
    return '${_formattedCurrencyToken(from, base)}≈${_formattedCurrencyToken(to, converted)}';
  }

  double _displayBaseAmountForPair(double pairRate) {
    if (pairRate < 0.0002) return 10000;
    if (pairRate < 0.002) return 1000;
    if (pairRate < 0.02) return 100;
    if (pairRate < 0.2) return 10;
    return 1;
  }

  String _fmtCurrencyAmount(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    if (value >= 1) return value.toStringAsFixed(2);
    if (value >= 0.1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nowUtc = liveData.nowUtc;
    final primaryZone = TimezoneUtils.nowInZone(
      primary.timeZoneId,
      nowUtc: nowUtc,
    );
    final secondaryZone = TimezoneUtils.nowInZone(
      secondary.timeZoneId,
      nowUtc: nowUtc,
    );
    final primaryNow = primaryZone.local;
    final secondaryNow = secondaryZone.local;
    final primaryTz = primaryZone.abbreviation;
    final secondaryTz = secondaryZone.abbreviation;

    final timeLine =
        '${_hm(primaryNow, use24h: primary.use24h)} $primaryTz  ·  '
        '${_hm(secondaryNow, use24h: secondary.use24h)} $secondaryTz';

    final primaryDate = _dayMonth(primaryNow);
    final secondaryDate = _dayMonth(secondaryNow);
    final dateLine = '($primaryDate · $secondaryDate)';

    final sun = liveData.sunFor(primary);
    final rise = sun?.sunriseUtc;
    final set = sun?.sunsetUtc;
    final riseLocal = rise == null
        ? null
        : TimezoneUtils.nowInZone(primary.timeZoneId, nowUtc: rise).local;
    final setLocal = set == null
        ? null
        : TimezoneUtils.nowInZone(primary.timeZoneId, nowUtc: set).local;

    final weather = liveData.weatherFor(primary);
    final windKmh = weather?.windKmh;
    final gustKmh = weather?.gustKmh;

    final env = liveData.envFor(primary);
    final aqi = env?.usAqi;
    final pollen = env?.pollenIndex;

    final line1 = <InlineSpan>[
      TextSpan(
        text: timeLine,
        style: GoogleFonts.robotoMono(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withAlpha(230),
        ),
      ),
      TextSpan(
        text: '  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: DraculaPalette.comment,
        ),
      ),
      TextSpan(
        text: TimezoneUtils.formatDeltaLabel(
          TimezoneUtils.deltaHours(primaryZone, secondaryZone),
        ),
        style: GoogleFonts.robotoMono(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: DraculaPalette.cyan,
        ),
      ),
    ];

    final line2 = <InlineSpan>[
      TextSpan(
        text: dateLine,
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
    ];

    final sunriseText = riseLocal == null
        ? '—'
        : _hm(riseLocal, use24h: primary.use24h);
    final sunsetText = setLocal == null
        ? '—'
        : _hm(setLocal, use24h: primary.use24h);

    final windText = _windLine(windKmh, place: primary);
    final gustText = _windLine(gustKmh, place: primary);

    final aqiBand = _aqiBandShort(aqi);
    final pollenBand = _pollenBandShort(pollen);

    final line3 = <InlineSpan>[
      TextSpan(
        text: '🌅 $sunriseText  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.pink,
        ),
      ),
      TextSpan(
        text: '🌇 $sunsetText  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.pink,
        ),
      ),
      TextSpan(
        text: '🌬 $windText  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
      TextSpan(
        text: '💨 $gustText',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
    ];

    final currency = _currencyLine();
    final line4 = <InlineSpan>[
      TextSpan(
        text: '■ ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: _aqiColor(aqi),
        ),
      ),
      TextSpan(
        text: 'AQI ${aqi ?? '—'}',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _aqiColor(aqi),
        ),
      ),
      if (aqiBand.isNotEmpty)
        TextSpan(
          text: ' $aqiBand',
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _aqiColor(aqi).withAlpha(220),
          ),
        ),
      TextSpan(
        text: '  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
      TextSpan(
        text: '🌸 Pollen ${pollen == null ? '—' : pollen.toStringAsFixed(1)}',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DraculaPalette.yellow,
        ),
      ),
      if (pollenBand.isNotEmpty)
        TextSpan(
          text: ' $pollenBand',
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DraculaPalette.yellow.withAlpha(220),
          ),
        ),
      TextSpan(
        text: '  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
      TextSpan(
        text: '🌡 ${_tempLine(weather, place: primary)}',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withAlpha(220),
        ),
      ),
      TextSpan(
        text: '  ·  ',
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DraculaPalette.comment,
        ),
      ),
      TextSpan(
        text: currency,
        style: GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: DraculaPalette.orange,
        ),
      ),
    ];

    final pillBg = cs.surfaceContainerHighest.withAlpha(77);
    final pillBorder = cs.outlineVariant.withAlpha(179);

    Widget richLine(
      List<InlineSpan> spans, {
      TextAlign align = TextAlign.left,
    }) {
      return _ScaleDownRichText(
        span: TextSpan(children: spans),
        textKey: ValueKey<String>('pinned_readout_${spans.length}_$align'),
        textAlign: align,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pillBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          richLine(line1, align: TextAlign.center),
          const SizedBox(height: 2),
          richLine(line2, align: TextAlign.center),
          const SizedBox(height: 5),
          richLine(line3, align: TextAlign.left),
          const SizedBox(height: 2),
          richLine(line4, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _ScaleDownRichText extends StatelessWidget {
  final InlineSpan span;
  final Key? textKey;
  final TextAlign textAlign;

  const _ScaleDownRichText({
    required this.span,
    this.textKey,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: _alignmentFor(textAlign),
      child: RichText(
        key: textKey,
        textAlign: textAlign,
        text: span,
        maxLines: 1,
        overflow: TextOverflow.visible,
        textScaler: const TextScaler.linear(1.0),
      ),
    );
  }

  Alignment _alignmentFor(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
