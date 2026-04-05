import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/tool_pace_energy_helpers.dart';
import 'package:unitana/features/dashboard/widgets/tool_helper_surfaces.dart';

void main() {
  ToolHelperSurfaceTheme buildTheme() {
    return const ToolHelperSurfaceTheme(
      accent: Colors.cyan,
      panelBg: Color(0xFF20232A),
      panelBgSoft: Color(0xFF2A2E36),
      panelBorder: Color(0xFF44475A),
      textMuted: Color(0xFFB0B7C3),
      headingTone: Colors.purpleAccent,
    );
  }

  testWidgets('hydration surface renders summary and climate callbacks', (
    tester,
  ) async {
    final weightController = TextEditingController(text: '70');
    final exerciseController = TextEditingController(text: '30');
    String selectedUnit = 'kg';
    String selectedClimate = 'temperate';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolHydrationSurface(
            toolId: 'hydration',
            weightController: weightController,
            exerciseController: exerciseController,
            weightUnit: selectedUnit,
            climateBand: selectedClimate,
            climateHelpText: 'Mild travel conditions with normal sweat loss.',
            invalidMessage: 'Enter valid weight and exercise minutes.',
            disclaimerText: 'This is a planning estimate, not medical advice.',
            resultSummary: 'Daily fluid estimate -> 2.7 L (91 fl oz)',
            theme: buildTheme(),
            onWeightChanged: (_) {},
            onExerciseChanged: (_) {},
            onSelectWeightUnit: (unit) {
              selectedUnit = unit;
            },
            onSelectClimateBand: (band) {
              selectedClimate = band;
            },
          ),
        ),
      ),
    );

    expect(
      find.text('Daily fluid estimate -> 2.7 L (91 fl oz)'),
      findsOneWidget,
    );
    expect(
      find.text('Mild travel conditions with normal sweat loss.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('tool_hydration_unit_hydration_lb')),
    );
    await tester.pump();
    expect(selectedUnit, 'lb');

    await tester.tap(
      find.byKey(const ValueKey('tool_hydration_climate_hydration_hot')),
    );
    await tester.pump();
    expect(selectedClimate, 'hot');
  });

  testWidgets('tip helper surface renders result shell and interactions', (
    tester,
  ) async {
    final amountController = TextEditingController(text: '100');
    int selectedPercent = 15;
    int splitCount = 1;
    String roundingMode = 'none';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTipHelperSurface(
            toolId: 'tip_helper',
            amountController: amountController,
            presetPercents: const [5, 10, 15, 20],
            selectedPercent: selectedPercent,
            splitCount: splitCount,
            roundingMode: roundingMode,
            amountLabel: 'Bill amount (USD)',
            amountHint: '100.00',
            splitLabel: 'Split',
            roundingChoices: const [
              ('none', 'None'),
              ('nearest', 'Nearest'),
              ('up', 'Up'),
              ('down', 'Down'),
            ],
            invalidAmountText: 'Enter a valid amount to calculate tip.',
            resultChild: const Text('Tip result body'),
            theme: buildTheme(),
            onAmountChanged: (_) {},
            onSelectPercent: (percent) {
              selectedPercent = percent;
            },
            onDecreaseSplit: () {
              splitCount -= 1;
            },
            onIncreaseSplit: () {
              splitCount += 1;
            },
            onSelectRoundingMode: (mode) {
              roundingMode = mode;
            },
          ),
        ),
      ),
    );

    expect(find.text('Tip result body'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_tip_chip_tip_helper_5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_tip_chip_tip_helper_10')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tool_tip_chip_tip_helper_20')));
    await tester.pump();
    expect(selectedPercent, 20);

    await tester.tap(
      find.byKey(const ValueKey('tool_tip_split_plus_tip_helper')),
    );
    await tester.pump();
    expect(splitCount, 2);

    await tester.tap(
      find.byKey(const ValueKey('tool_tip_round_tip_helper_up')),
    );
    await tester.pump();
    expect(roundingMode, 'up');
  });

  testWidgets('tax vat surface renders manual rate field and mode controls', (
    tester,
  ) async {
    final amountController = TextEditingController(text: '120');
    final rateController = TextEditingController(text: '23');
    bool isAddOn = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTaxVatSurface(
            toolId: 'tax_vat_helper',
            amountController: amountController,
            rateController: rateController,
            isAddOn: isAddOn,
            amountLabel: 'Total paid (EUR)',
            amountHint: '100.00',
            rateLabel: 'Rate',
            rateHint: '23',
            presetContextText:
                'Enter the exact local rate if you know it. Typical pricing context is based on Porto, PT (EUR), but the rate stays fully manual.',
            addOnModeLabel: 'Add tax to price',
            inclusiveModeLabel: 'Find tax in total',
            invalidAmountText: 'Enter a valid amount to calculate tax.',
            modeHelpText:
                'Use this when tax or VAT is already included in the total.',
            resultChild: const Text('Tax result body'),
            theme: buildTheme(),
            onAmountChanged: (_) {},
            onRateChanged: (_) {},
            onSelectMode: (next) {
              isAddOn = next;
            },
          ),
        ),
      ),
    );

    expect(find.text('Tax result body'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_tax_rate_tax_vat_helper')),
      findsOneWidget,
    );
    expect(find.byType(ChoiceChip), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey('tool_tax_mode_tax_vat_helper_add_on')),
    );
    await tester.pump();
    expect(isAddOn, isTrue);
  });

  testWidgets('unit price surface renders compare flow and callbacks', (
    tester,
  ) async {
    final priceA = TextEditingController(text: '4.99');
    final qtyA = TextEditingController(text: '500');
    final priceB = TextEditingController(text: '7.50');
    final qtyB = TextEditingController(text: '1000');
    bool compareEnabled = true;
    String pickedKey = '';
    int swapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolUnitPriceSurface(
            toolId: 'unit_price_helper',
            coachText: 'Compare normalized shelf prices before you buy.',
            currencyContextText: 'Denver (USD) • Porto (EUR)',
            quickSteps: const [
              ('1 Price', Icons.local_offer_rounded),
              ('2 Units', Icons.straighten_rounded),
            ],
            productA: ToolUnitPriceProductConfig(
              title: 'Product A',
              priceController: priceA,
              qtyController: qtyA,
              selectedUnit: 'g',
              keyPrefix: 'unit_price_helper_a',
              isPrimaryCard: true,
            ),
            productB: ToolUnitPriceProductConfig(
              title: 'Product B',
              priceController: priceB,
              qtyController: qtyB,
              selectedUnit: 'g',
              keyPrefix: 'unit_price_helper_b',
              isPrimaryCard: false,
            ),
            compareEnabled: compareEnabled,
            compareToggleLabel: 'Compare with Product B',
            swapLabel: 'Swap',
            invalidProductText: 'Add valid price and units',
            resultChild: const Text('Comparison result'),
            theme: buildTheme(),
            onPriceChanged: (_) {},
            onQtyChanged: (_) {},
            onPickUnit: (keyPrefix, selectedUnit) async {
              pickedKey = '$keyPrefix:$selectedUnit';
            },
            onCompareEnabledChanged: (value) {
              compareEnabled = value;
            },
            onSwapProducts: () {
              swapCount += 1;
            },
          ),
        ),
      ),
    );

    expect(find.text('Compare with Product B'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('tool_unit_price_unit_unit_price_helper_a')),
    );
    await tester.pump();
    expect(pickedKey, 'unit_price_helper_a:g');

    await tester.tap(
      find.byKey(const ValueKey('tool_unit_price_swap_unit_price_helper')),
    );
    await tester.pump();
    expect(swapCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('tool_unit_price_compare_unit_price_helper')),
    );
    await tester.pump();
    expect(compareEnabled, false);
  });

  testWidgets('pace insights surface renders planning callbacks', (
    tester,
  ) async {
    final builderDistance = TextEditingController(text: '5');
    final builderTime = TextEditingController(text: '25:00');
    final goalTime = TextEditingController(text: '52:00');
    PaceActivityMode selectedMode = PaceActivityMode.running;
    String selectedUnit = 'km';
    double selectedGoalDistance = 10;
    int applyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ToolPaceInsightsSurface(
              paceMode: selectedMode,
              builderDistanceUnit: selectedUnit,
              builderDistanceController: builderDistance,
              builderTimeController: builderTime,
              goalTimeController: goalTime,
              currentPerKm: 5.0,
              currentPerMi: 8.04672,
              currentKmh: 12.0,
              currentMph: 7.45,
              raceTargets: const [PaceDistanceTarget(label: '5K', km: 5)],
              builderResult: const PaceBuilderResult(
                distanceKm: 5.0,
                perKmMinutes: 5.0,
                perMiMinutes: 8.04672,
                split500Minutes: 2.5,
              ),
              goalTargets: const [
                PaceDistanceTarget(label: '10K', km: 10),
                PaceDistanceTarget(label: 'Half', km: 21.0975),
              ],
              selectedGoalDistanceKm: selectedGoalDistance,
              goalResult: PaceGoalResult(
                perKmMinutes: 5.2,
                perMiMinutes: 8.3685888,
                split500Minutes: 2.6,
                checkpoints: const [
                  PaceCheckpoint(label: '5K • halfway', minutes: 26),
                ],
              ),
              theme: buildTheme(),
              emptyGoalText: 'Enter a goal time to see required pace.',
              onModeChanged: (mode) {
                selectedMode = mode;
              },
              onBuilderDistanceChanged: (_) {},
              onBuilderUnitChanged: (unit) {
                selectedUnit = unit;
              },
              onBuilderTimeChanged: (_) {},
              onApplyBuilderResult: () {
                applyCount += 1;
              },
              onGoalDistanceChanged: (km) {
                selectedGoalDistance = km;
              },
              onGoalTimeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('tool_pace_insights_card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tool_pace_builder_unit_mi')));
    await tester.pump();
    expect(selectedUnit, 'mi');

    await tester.tap(find.byKey(const ValueKey('tool_pace_builder_apply')));
    await tester.pump();
    expect(applyCount, 1);

    await tester.tap(find.byKey(const ValueKey('tool_pace_goal_dist_Half')));
    await tester.pump();
    expect(selectedGoalDistance, 21.0975);

    await tester.tap(find.text('Row'));
    await tester.pump();
    expect(selectedMode, PaceActivityMode.rowing);
  });
}
