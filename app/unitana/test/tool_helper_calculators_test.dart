import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/tool_helper_calculators.dart';

void main() {
  test('tip presets vary by country', () {
    expect(tipPresetsForCountry('US'), const <int>[15, 18, 20]);
    expect(tipPresetsForCountry('pt'), const <int>[5, 10, 15]);
    expect(tipPresetsForCountry('JP'), const <int>[0, 5, 10]);
  });

  test('computeTip applies percent, split, and rounding', () {
    final result = computeTip(
      amount: 99,
      tipPercent: 18,
      splitCount: 3,
      roundingMode: 'up',
    );

    expect(result, isNotNull);
    expect(result!.tipAmount, closeTo(17.82, 0.001));
    expect(result.totalBeforeRounding, closeTo(116.82, 0.001));
    expect(result.totalAmount, 117);
    expect(result.perPersonAmount, 39);
    expect(result.roundDelta, closeTo(0.18, 0.001));
  });

  test('computeTaxBreakdown handles add-on and inclusive modes', () {
    final addOn = computeTaxBreakdown(
      amount: 100,
      taxPercent: 8,
      isAddOn: true,
    );
    final inclusive = computeTaxBreakdown(
      amount: 120,
      taxPercent: 20,
      isAddOn: false,
    );

    expect(addOn, isNotNull);
    expect(addOn!.subtotal, 100);
    expect(addOn.taxAmount, 8);
    expect(addOn.totalAmount, 108);

    expect(inclusive, isNotNull);
    expect(inclusive!.subtotal, closeTo(100, 0.001));
    expect(inclusive.taxAmount, closeTo(20, 0.001));
    expect(inclusive.totalAmount, 120);
  });

  test(
    'computeHydrationEstimate combines base, exercise, and climate load',
    () {
      final result = computeHydrationEstimate(
        weightKg: 70,
        exerciseMinutes: 45,
        climateBand: 'warm',
      );

      expect(result, isNotNull);
      expect(result!.baseLiters, closeTo(2.31, 0.001));
      expect(result.exerciseLiters, closeTo(0.27, 0.001));
      expect(result.climateLiters, closeTo(0.35, 0.001));
      expect(result.totalLiters, closeTo(2.93, 0.001));
      expect(result.totalFluidOunces, closeTo(99.08, 0.05));
    },
  );

  test('unit price helpers normalize mass and compare products', () {
    final productA = computeUnitPriceMetrics(
      price: 4.99,
      quantity: 500,
      unit: 'g',
    );
    final productB = computeUnitPriceMetrics(
      price: 6.49,
      quantity: 750,
      unit: 'g',
    );
    final comparison = computeUnitPriceComparison(
      compareEnabled: true,
      productA: productA,
      productB: productB,
    );

    expect(productA, isNotNull);
    expect(productA!.unitFamily, UnitPriceUnitFamily.mass);
    expect(productA.per100Amount, closeTo(0.998, 0.001));
    expect(productA.per1000Amount, closeTo(9.98, 0.01));
    expect(productA.normalizedTargetLabel, '1 kg');

    expect(productB, isNotNull);
    expect(productB!.per100Amount, closeTo(0.8653, 0.001));

    expect(comparison, isNotNull);
    expect(comparison!.comparable, isTrue);
    expect(comparison.cheaperProduct, 'b');
    expect(comparison.percentDifference, closeTo(15.3, 0.2));
  });

  test('unit price comparison rejects mixed families', () {
    final mass = computeUnitPriceMetrics(price: 4.99, quantity: 500, unit: 'g');
    final volume = computeUnitPriceMetrics(
      price: 3.49,
      quantity: 500,
      unit: 'mL',
    );
    final comparison = computeUnitPriceComparison(
      compareEnabled: true,
      productA: mass,
      productB: volume,
    );

    expect(unitPriceSameFamily('g', 'kg'), isTrue);
    expect(unitPriceSameFamily('g', 'mL'), isFalse);
    expect(unitPriceDefaultFamilyUnitFor('fl oz'), 'mL');
    expect(comparison, isNotNull);
    expect(comparison!.comparable, isFalse);
  });
}
