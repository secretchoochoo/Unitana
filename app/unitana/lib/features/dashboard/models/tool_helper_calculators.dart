import 'dart:math' as math;

import 'package:flutter/foundation.dart';

List<int> tipPresetsForCountry(String countryCode) {
  switch (countryCode.trim().toUpperCase()) {
    case 'US':
    case 'CA':
      return const <int>[15, 18, 20];
    case 'JP':
    case 'KR':
      return const <int>[0, 5, 10];
    case 'PT':
    case 'ES':
    case 'IT':
    case 'FR':
    case 'DE':
      return const <int>[5, 10, 15];
    default:
      return const <int>[10, 15, 20];
  }
}

List<int> taxPresetsForCountry(String countryCode) {
  switch (countryCode.trim().toUpperCase()) {
    case 'US':
      return const <int>[6, 8, 10];
    case 'CA':
      return const <int>[5, 13, 15];
    case 'GB':
    case 'FR':
    case 'DE':
    case 'IT':
    case 'ES':
      return const <int>[5, 10, 20];
    case 'JP':
      return const <int>[8, 10];
    default:
      return const <int>[5, 8, 10];
  }
}

double applyTipRounding(double value, String roundingMode) {
  switch (roundingMode) {
    case 'nearest':
      return value.roundToDouble();
    case 'up':
      return value.ceilToDouble();
    case 'down':
      return value.floorToDouble();
    case 'none':
    default:
      return value;
  }
}

@immutable
class TipComputation {
  final double tipAmount;
  final double totalBeforeRounding;
  final double totalAmount;
  final double perPersonAmount;
  final double roundDelta;

  const TipComputation({
    required this.tipAmount,
    required this.totalBeforeRounding,
    required this.totalAmount,
    required this.perPersonAmount,
    required this.roundDelta,
  });
}

TipComputation? computeTip({
  required double? amount,
  required int tipPercent,
  required int splitCount,
  required String roundingMode,
}) {
  if (amount == null || splitCount <= 0) return null;
  final tipAmount = amount * (tipPercent / 100.0);
  final totalBeforeRounding = amount + tipAmount;
  final totalAmount = applyTipRounding(totalBeforeRounding, roundingMode);
  return TipComputation(
    tipAmount: tipAmount,
    totalBeforeRounding: totalBeforeRounding,
    totalAmount: totalAmount,
    perPersonAmount: totalAmount / splitCount,
    roundDelta: totalAmount - totalBeforeRounding,
  );
}

@immutable
class TaxBreakdown {
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final bool isAddOn;

  const TaxBreakdown({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.isAddOn,
  });
}

TaxBreakdown? computeTaxBreakdown({
  required double? amount,
  required int taxPercent,
  required bool isAddOn,
}) {
  if (amount == null) return null;
  final rate = taxPercent / 100.0;
  final subtotal = isAddOn ? amount : amount / (1.0 + rate);
  final taxAmount = isAddOn ? amount * rate : amount - subtotal;
  final totalAmount = isAddOn ? amount + taxAmount : amount;
  return TaxBreakdown(
    subtotal: subtotal,
    taxAmount: taxAmount,
    totalAmount: totalAmount,
    isAddOn: isAddOn,
  );
}

double hydrationClimateLitersBonus(String climateBand) {
  switch (climateBand) {
    case 'cool':
      return 0.0;
    case 'warm':
      return 0.35;
    case 'hot':
      return 0.7;
    case 'temperate':
    default:
      return 0.15;
  }
}

@immutable
class HydrationEstimate {
  final double baseLiters;
  final double exerciseLiters;
  final double climateLiters;
  final double totalLiters;
  final double totalFluidOunces;

  const HydrationEstimate({
    required this.baseLiters,
    required this.exerciseLiters,
    required this.climateLiters,
    required this.totalLiters,
    required this.totalFluidOunces,
  });
}

HydrationEstimate? computeHydrationEstimate({
  required double? weightKg,
  required int? exerciseMinutes,
  required String climateBand,
}) {
  if (weightKg == null || exerciseMinutes == null) return null;
  final baseLiters = weightKg * 0.033;
  final exerciseLiters = exerciseMinutes * 0.006;
  final climateLiters = hydrationClimateLitersBonus(climateBand);
  final totalLiters = math.max(
    1.0,
    baseLiters + exerciseLiters + climateLiters,
  );
  return HydrationEstimate(
    baseLiters: baseLiters,
    exerciseLiters: exerciseLiters,
    climateLiters: climateLiters,
    totalLiters: totalLiters,
    totalFluidOunces: totalLiters * 33.814,
  );
}

enum UnitPriceUnitFamily { mass, volume, unknown }

const List<String> kUnitPriceUnits = <String>[
  'g',
  'kg',
  'oz',
  'lb',
  'mL',
  'L',
  'fl oz',
];

const Map<String, double> _unitPriceMassToG = <String, double>{
  'g': 1.0,
  'kg': 1000.0,
  'oz': 28.349523125,
  'lb': 453.59237,
};

const Map<String, double> _unitPriceVolumeToMl = <String, double>{
  'mL': 1.0,
  'L': 1000.0,
  'fl oz': 29.5735295625,
};

bool unitPriceIsMassUnit(String unit) => _unitPriceMassToG.containsKey(unit);

bool unitPriceIsVolumeUnit(String unit) =>
    _unitPriceVolumeToMl.containsKey(unit);

bool unitPriceSameFamily(String a, String b) {
  return (unitPriceIsMassUnit(a) && unitPriceIsMassUnit(b)) ||
      (unitPriceIsVolumeUnit(a) && unitPriceIsVolumeUnit(b));
}

String unitPriceDefaultFamilyUnitFor(String unit) {
  if (unitPriceIsMassUnit(unit)) return 'g';
  if (unitPriceIsVolumeUnit(unit)) return 'mL';
  return 'g';
}

double? unitPriceToBaseAmount({
  required double quantity,
  required String unit,
}) {
  final massFactor = _unitPriceMassToG[unit];
  if (massFactor != null) return quantity * massFactor;
  final volumeFactor = _unitPriceVolumeToMl[unit];
  if (volumeFactor != null) return quantity * volumeFactor;
  return null;
}

@immutable
class UnitPriceMetrics {
  final UnitPriceUnitFamily unitFamily;
  final double perBaseAmount;
  final double per100Amount;
  final double per1000Amount;
  final String normalizedTargetLabel;
  final String benchmarkShortLabel;
  final String benchmarkLongLabel;

  const UnitPriceMetrics({
    required this.unitFamily,
    required this.perBaseAmount,
    required this.per100Amount,
    required this.per1000Amount,
    required this.normalizedTargetLabel,
    required this.benchmarkShortLabel,
    required this.benchmarkLongLabel,
  });
}

UnitPriceMetrics? computeUnitPriceMetrics({
  required double? price,
  required double? quantity,
  required String unit,
}) {
  if (price == null || quantity == null) return null;
  final baseAmount = unitPriceToBaseAmount(quantity: quantity, unit: unit);
  if (baseAmount == null || baseAmount <= 0) return null;

  if (unitPriceIsMassUnit(unit)) {
    return UnitPriceMetrics(
      unitFamily: UnitPriceUnitFamily.mass,
      perBaseAmount: price / baseAmount,
      per100Amount: (price / baseAmount) * 100.0,
      per1000Amount: (price / baseAmount) * 1000.0,
      normalizedTargetLabel: '1 kg',
      benchmarkShortLabel: '100g',
      benchmarkLongLabel: '1 kg',
    );
  }

  if (unitPriceIsVolumeUnit(unit)) {
    return UnitPriceMetrics(
      unitFamily: UnitPriceUnitFamily.volume,
      perBaseAmount: price / baseAmount,
      per100Amount: (price / baseAmount) * 100.0,
      per1000Amount: (price / baseAmount) * 1000.0,
      normalizedTargetLabel: '1 L',
      benchmarkShortLabel: '100mL',
      benchmarkLongLabel: '1 L',
    );
  }

  return UnitPriceMetrics(
    unitFamily: UnitPriceUnitFamily.unknown,
    perBaseAmount: price / baseAmount,
    per100Amount: price / baseAmount,
    per1000Amount: price / baseAmount,
    normalizedTargetLabel: '1 base',
    benchmarkShortLabel: 'base unit',
    benchmarkLongLabel: '1 base unit',
  );
}

@immutable
class UnitPriceComparison {
  final bool comparable;
  final bool equalPrice;
  final String? cheaperProduct;
  final double? percentDifference;

  const UnitPriceComparison({
    required this.comparable,
    required this.equalPrice,
    this.cheaperProduct,
    this.percentDifference,
  });
}

UnitPriceComparison? computeUnitPriceComparison({
  required bool compareEnabled,
  required UnitPriceMetrics? productA,
  required UnitPriceMetrics? productB,
}) {
  if (!compareEnabled || productA == null || productB == null) return null;
  if (productA.unitFamily != productB.unitFamily) {
    return const UnitPriceComparison(comparable: false, equalPrice: false);
  }

  final perBaseA = productA.perBaseAmount;
  final perBaseB = productB.perBaseAmount;
  final delta = (perBaseA - perBaseB).abs();
  final pct = (delta / math.min(perBaseA, perBaseB)) * 100.0;

  if (perBaseA < perBaseB) {
    return UnitPriceComparison(
      comparable: true,
      equalPrice: false,
      cheaperProduct: 'a',
      percentDifference: pct,
    );
  }

  if (perBaseB < perBaseA) {
    return UnitPriceComparison(
      comparable: true,
      equalPrice: false,
      cheaperProduct: 'b',
      percentDifference: pct,
    );
  }

  return const UnitPriceComparison(comparable: true, equalPrice: true);
}
