import 'package:flutter/material.dart';

import '../models/tool_pace_energy_helpers.dart';

@immutable
class ToolHelperSurfaceTheme {
  final Color accent;
  final Color panelBg;
  final Color panelBgSoft;
  final Color panelBorder;
  final Color textMuted;
  final Color headingTone;

  const ToolHelperSurfaceTheme({
    required this.accent,
    required this.panelBg,
    required this.panelBgSoft,
    required this.panelBorder,
    required this.textMuted,
    required this.headingTone,
  });
}

class ToolHydrationSurface extends StatelessWidget {
  final String toolId;
  final TextEditingController weightController;
  final TextEditingController exerciseController;
  final String weightUnit;
  final String climateBand;
  final String climateHelpText;
  final String invalidMessage;
  final String disclaimerText;
  final String? resultSummary;
  final ToolHelperSurfaceTheme theme;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onExerciseChanged;
  final ValueChanged<String> onSelectWeightUnit;
  final ValueChanged<String> onSelectClimateBand;

  const ToolHydrationSurface({
    super.key,
    required this.toolId,
    required this.weightController,
    required this.exerciseController,
    required this.weightUnit,
    required this.climateBand,
    required this.climateHelpText,
    required this.invalidMessage,
    required this.disclaimerText,
    required this.resultSummary,
    required this.theme,
    required this.onWeightChanged,
    required this.onExerciseChanged,
    required this.onSelectWeightUnit,
    required this.onSelectClimateBand,
  });

  String _climateLabel(String band) {
    switch (band) {
      case 'cool':
        return 'Cool';
      case 'warm':
        return 'Warm';
      case 'hot':
        return 'Hot';
      case 'temperate':
      default:
        return 'Temperate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('tool_hydration_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_hydration_weight_$toolId'),
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Body weight ($weightUnit)',
            hintText: weightUnit == 'kg' ? '70' : '155',
          ),
          onChanged: onWeightChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: ValueKey('tool_hydration_unit_${toolId}_kg'),
              label: const Text('kg'),
              selected: weightUnit == 'kg',
              onSelected: (_) => onSelectWeightUnit('kg'),
            ),
            ChoiceChip(
              key: ValueKey('tool_hydration_unit_${toolId}_lb'),
              label: const Text('lb'),
              selected: weightUnit == 'lb',
              onSelected: (_) => onSelectWeightUnit('lb'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: ValueKey('tool_hydration_exercise_$toolId'),
          controller: exerciseController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Exercise minutes today',
            hintText: '30',
          ),
          onChanged: onExerciseChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['cool', 'temperate', 'warm', 'hot'].map((band) {
            return ChoiceChip(
              key: ValueKey('tool_hydration_climate_${toolId}_$band'),
              label: Text(_climateLabel(band)),
              selected: climateBand == band,
              onSelected: (_) => onSelectClimateBand(band),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          climateHelpText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: theme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_hydration_result_$toolId'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child: resultSummary == null
              ? Text(
                  invalidMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resultSummary!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      disclaimerText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

@immutable
class ToolUnitPriceProductConfig {
  final String title;
  final TextEditingController priceController;
  final TextEditingController qtyController;
  final String selectedUnit;
  final String keyPrefix;
  final bool isPrimaryCard;

  const ToolUnitPriceProductConfig({
    required this.title,
    required this.priceController,
    required this.qtyController,
    required this.selectedUnit,
    required this.keyPrefix,
    required this.isPrimaryCard,
  });
}

class ToolTipHelperSurface extends StatelessWidget {
  final String toolId;
  final TextEditingController amountController;
  final List<int> presetPercents;
  final int selectedPercent;
  final int splitCount;
  final String roundingMode;
  final String amountLabel;
  final String amountHint;
  final String splitLabel;
  final List<(String, String)> roundingChoices;
  final String invalidAmountText;
  final Widget? resultChild;
  final ToolHelperSurfaceTheme theme;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<int> onSelectPercent;
  final VoidCallback? onDecreaseSplit;
  final VoidCallback onIncreaseSplit;
  final ValueChanged<String> onSelectRoundingMode;

  const ToolTipHelperSurface({
    super.key,
    required this.toolId,
    required this.amountController,
    required this.presetPercents,
    required this.selectedPercent,
    required this.splitCount,
    required this.roundingMode,
    required this.amountLabel,
    required this.amountHint,
    required this.splitLabel,
    required this.roundingChoices,
    required this.invalidAmountText,
    required this.resultChild,
    required this.theme,
    required this.onAmountChanged,
    required this.onSelectPercent,
    required this.onDecreaseSplit,
    required this.onIncreaseSplit,
    required this.onSelectRoundingMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('tool_tip_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_tip_amount_$toolId'),
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: amountLabel,
            hintText: amountHint,
          ),
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final percent in presetPercents)
              ChoiceChip(
                key: ValueKey('tool_tip_chip_${toolId}_$percent'),
                label: Text('$percent%'),
                selected: selectedPercent == percent,
                onSelected: (_) => onSelectPercent(percent),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              splitLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.headingTone,
              ),
            ),
            const Spacer(),
            IconButton(
              key: ValueKey('tool_tip_split_minus_$toolId'),
              onPressed: onDecreaseSplit,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text(
              '$splitCount',
              key: ValueKey('tool_tip_split_value_$toolId'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            IconButton(
              key: ValueKey('tool_tip_split_plus_$toolId'),
              onPressed: onIncreaseSplit,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roundingChoices.map((choice) {
            return ChoiceChip(
              key: ValueKey('tool_tip_round_${toolId}_${choice.$1}'),
              label: Text(choice.$2),
              selected: roundingMode == choice.$1,
              onSelected: (_) => onSelectRoundingMode(choice.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_tip_result_$toolId'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child:
              resultChild ??
              Text(
                invalidAmountText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ),
      ],
    );
  }
}

class ToolTaxVatSurface extends StatelessWidget {
  final String toolId;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final bool isAddOn;
  final String amountLabel;
  final String amountHint;
  final String rateLabel;
  final String rateHint;
  final String presetContextText;
  final String addOnModeLabel;
  final String inclusiveModeLabel;
  final String invalidAmountText;
  final String? modeHelpText;
  final Widget? resultChild;
  final ToolHelperSurfaceTheme theme;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onRateChanged;
  final ValueChanged<bool> onSelectMode;

  const ToolTaxVatSurface({
    super.key,
    required this.toolId,
    required this.amountController,
    required this.rateController,
    required this.isAddOn,
    required this.amountLabel,
    required this.amountHint,
    required this.rateLabel,
    required this.rateHint,
    required this.presetContextText,
    required this.addOnModeLabel,
    required this.inclusiveModeLabel,
    required this.invalidAmountText,
    required this.modeHelpText,
    required this.resultChild,
    required this.theme,
    required this.onAmountChanged,
    required this.onRateChanged,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('tool_tax_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        TextField(
          key: ValueKey('tool_tax_amount_$toolId'),
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: amountLabel,
            hintText: amountHint,
          ),
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          key: ValueKey('tool_tax_rate_$toolId'),
          controller: rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: rateLabel,
            hintText: rateHint,
            suffixText: '%',
          ),
          onChanged: onRateChanged,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.panelBorder),
          ),
          child: Text(
            presetContextText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: ValueKey('tool_tax_mode_${toolId}_add_on'),
              label: Text(addOnModeLabel),
              selected: isAddOn,
              onSelected: (_) => onSelectMode(true),
            ),
            ChoiceChip(
              key: ValueKey('tool_tax_mode_${toolId}_inclusive'),
              label: Text(inclusiveModeLabel),
              selected: !isAddOn,
              onSelected: (_) => onSelectMode(false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          key: ValueKey('tool_tax_result_$toolId'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child:
              resultChild ??
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invalidAmountText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (modeHelpText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      modeHelpText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
        ),
      ],
    );
  }
}

class ToolEnergyPlannerSurface extends StatelessWidget {
  final TextEditingController weightController;
  final String weightUnit;
  final String activityLevel;
  final String activityHelpText;
  final String? estimateSummary;
  final String emptyPrompt;
  final ToolHelperSurfaceTheme theme;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onSelectWeightUnit;
  final ValueChanged<String> onSelectActivity;

  const ToolEnergyPlannerSurface({
    super.key,
    required this.weightController,
    required this.weightUnit,
    required this.activityLevel,
    required this.activityHelpText,
    required this.estimateSummary,
    required this.emptyPrompt,
    required this.theme,
    required this.onWeightChanged,
    required this.onSelectWeightUnit,
    required this.onSelectActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('tool_energy_planner_card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Energy Estimate',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: theme.headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rough maintenance estimate based on body weight and typical daily activity.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('tool_energy_weight_input'),
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Body weight',
                    hintText: '70',
                  ),
                  onChanged: onWeightChanged,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                key: const ValueKey('tool_energy_weight_unit_kg'),
                label: const Text('kg'),
                selected: weightUnit == 'kg',
                onSelected: (_) => onSelectWeightUnit('kg'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                key: const ValueKey('tool_energy_weight_unit_lb'),
                label: const Text('lb'),
                selected: weightUnit == 'lb',
                onSelected: (_) => onSelectWeightUnit('lb'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_light'),
                label: const Text('Light'),
                selected: activityLevel == 'light',
                onSelected: (_) => onSelectActivity('light'),
              ),
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_moderate'),
                label: const Text('Moderate'),
                selected: activityLevel == 'moderate',
                onSelected: (_) => onSelectActivity('moderate'),
              ),
              ChoiceChip(
                key: const ValueKey('tool_energy_activity_high'),
                label: const Text('High'),
                selected: activityLevel == 'high',
                onSelected: (_) => onSelectActivity('high'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activityHelpText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estimateSummary ?? emptyPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: estimateSummary == null ? theme.textMuted : theme.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ToolUnitPriceSurface extends StatelessWidget {
  final String toolId;
  final String coachText;
  final String? currencyContextText;
  final List<(String, IconData)> quickSteps;
  final ToolUnitPriceProductConfig productA;
  final ToolUnitPriceProductConfig? productB;
  final bool compareEnabled;
  final String compareToggleLabel;
  final String swapLabel;
  final String invalidProductText;
  final Widget resultChild;
  final ToolHelperSurfaceTheme theme;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onQtyChanged;
  final Future<void> Function(String keyPrefix, String selectedUnit) onPickUnit;
  final ValueChanged<bool> onCompareEnabledChanged;
  final VoidCallback onSwapProducts;

  const ToolUnitPriceSurface({
    super.key,
    required this.toolId,
    required this.coachText,
    required this.currencyContextText,
    required this.quickSteps,
    required this.productA,
    required this.productB,
    required this.compareEnabled,
    required this.compareToggleLabel,
    required this.swapLabel,
    required this.invalidProductText,
    required this.resultChild,
    required this.theme,
    required this.onPriceChanged,
    required this.onQtyChanged,
    required this.onPickUnit,
    required this.onCompareEnabledChanged,
    required this.onSwapProducts,
  });

  @override
  Widget build(BuildContext context) {
    Widget quickStep((String, IconData) step) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(step.$2, size: 14, color: theme.accent.withAlpha(210)),
            const SizedBox(width: 6),
            Text(
              step.$1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    Widget productCard(ToolUnitPriceProductConfig config) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: config.isPrimaryCard ? theme.panelBg : theme.panelBgSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('tool_unit_price_price_${config.keyPrefix}'),
              controller: config.priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: '4.99',
              ),
              onChanged: onPriceChanged,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: ValueKey(
                          'tool_unit_price_qty_${config.keyPrefix}',
                        ),
                        controller: config.qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: '500',
                        ),
                        onChanged: onQtyChanged,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter unit amount (g, oz, mL, L).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      key: ValueKey('tool_unit_price_unit_${config.keyPrefix}'),
                      onPressed: () =>
                          onPickUnit(config.keyPrefix, config.selectedUnit),
                      child: Text(config.selectedUnit),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView(
      key: ValueKey('tool_unit_price_scroll_$toolId'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.panelBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coachText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickSteps.map(quickStep).toList(),
              ),
            ],
          ),
        ),
        if (currencyContextText != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: theme.panelBgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.panelBorder),
            ),
            child: Text(
              currencyContextText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        productCard(productA),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          key: ValueKey('tool_unit_price_compare_$toolId'),
          value: compareEnabled,
          contentPadding: EdgeInsets.zero,
          title: Text(
            compareToggleLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          onChanged: onCompareEnabledChanged,
        ),
        if (compareEnabled && productB != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: ValueKey('tool_unit_price_swap_$toolId'),
              onPressed: onSwapProducts,
              icon: const Icon(Icons.swap_vert_rounded),
              label: Text(swapLabel),
            ),
          ),
          const SizedBox(height: 8),
          productCard(productB!),
          const SizedBox(height: 8),
        ],
        Container(
          key: ValueKey('tool_unit_price_result_$toolId'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child: resultChild,
        ),
      ],
    );
  }
}

class ToolPaceInsightsSurface extends StatelessWidget {
  final PaceActivityMode paceMode;
  final String builderDistanceUnit;
  final TextEditingController builderDistanceController;
  final TextEditingController builderTimeController;
  final TextEditingController goalTimeController;
  final double currentPerKm;
  final double currentPerMi;
  final double currentKmh;
  final double currentMph;
  final List<PaceDistanceTarget> raceTargets;
  final PaceBuilderResult? builderResult;
  final List<PaceDistanceTarget> goalTargets;
  final double selectedGoalDistanceKm;
  final PaceGoalResult? goalResult;
  final ToolHelperSurfaceTheme theme;
  final String emptyGoalText;
  final ValueChanged<PaceActivityMode> onModeChanged;
  final ValueChanged<String> onBuilderDistanceChanged;
  final ValueChanged<String> onBuilderUnitChanged;
  final ValueChanged<String> onBuilderTimeChanged;
  final VoidCallback onApplyBuilderResult;
  final ValueChanged<double> onGoalDistanceChanged;
  final ValueChanged<String> onGoalTimeChanged;

  const ToolPaceInsightsSurface({
    super.key,
    required this.paceMode,
    required this.builderDistanceUnit,
    required this.builderDistanceController,
    required this.builderTimeController,
    required this.goalTimeController,
    required this.currentPerKm,
    required this.currentPerMi,
    required this.currentKmh,
    required this.currentMph,
    required this.raceTargets,
    required this.builderResult,
    required this.goalTargets,
    required this.selectedGoalDistanceKm,
    required this.goalResult,
    required this.theme,
    required this.emptyGoalText,
    required this.onModeChanged,
    required this.onBuilderDistanceChanged,
    required this.onBuilderUnitChanged,
    required this.onBuilderTimeChanged,
    required this.onApplyBuilderResult,
    required this.onGoalDistanceChanged,
    required this.onGoalTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = theme.panelBg;
    final panelBorder = theme.panelBorder;
    final textMuted = theme.textMuted;
    final headingTone = theme.headingTone;

    return Container(
      key: const ValueKey('tool_pace_insights_card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pace Insights',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatPace(currentPerKm)} min/km • ${formatPace(currentPerMi)} min/mi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${currentKmh.toStringAsFixed(1)} km/h • ${currentMph.toStringAsFixed(1)} mph',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textMuted.withAlpha(236),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PaceActivityMode>(
            key: const ValueKey('tool_pace_mode'),
            segments: const [
              ButtonSegment(
                value: PaceActivityMode.running,
                label: Text('Run'),
              ),
              ButtonSegment(value: PaceActivityMode.rowing, label: Text('Row')),
            ],
            selected: {paceMode},
            onSelectionChanged: (selection) {
              onModeChanged(
                selection.isEmpty ? PaceActivityMode.running : selection.first,
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final target in raceTargets)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelBg.withAlpha(216),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: panelBorder.withAlpha(170)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Text(
                      '${target.label} ${formatDurationMinutes(currentPerKm * target.km)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: panelBorder.withAlpha(150)),
          const SizedBox(height: 10),
          Text(
            'Distance + Time -> Pace',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('tool_pace_builder_distance'),
                  controller: builderDistanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: paceBuilderDistanceHint(paceMode),
                    labelText: 'Distance',
                  ),
                  onChanged: onBuilderDistanceChanged,
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final unit in paceBuilderDistanceUnits(paceMode))
                    ChoiceChip(
                      key: ValueKey('tool_pace_builder_unit_$unit'),
                      label: Text(unit),
                      selected: builderDistanceUnit == unit,
                      onSelected: (_) => onBuilderUnitChanged(unit),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('tool_pace_builder_time'),
            controller: builderTimeController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: 'Duration (mm:ss or h:mm:ss)',
            ),
            onChanged: onBuilderTimeChanged,
          ),
          if (builderResult != null) ...[
            const SizedBox(height: 8),
            Text(
              'Derived pace: ${formatPace(builderResult!.perKmMinutes)} min/km • ${formatPace(builderResult!.perMiMinutes)} min/mi'
              ' • ${formatPace(builderResult!.split500Minutes)} /500m',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('tool_pace_builder_apply'),
                onPressed: onApplyBuilderResult,
                icon: const Icon(Icons.input_rounded, size: 16),
                label: const Text('Use as input pace'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: panelBorder.withAlpha(150)),
          const SizedBox(height: 10),
          Text(
            'Goal Planner',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: headingTone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final item in goalTargets)
                ChoiceChip(
                  key: ValueKey('tool_pace_goal_dist_${item.label}'),
                  label: Text(item.label),
                  selected: selectedGoalDistanceKm == item.km,
                  onSelected: (_) => onGoalDistanceChanged(item.km),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('tool_pace_goal_input'),
            controller: goalTimeController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: 'Goal time (mm:ss or h:mm:ss)',
            ),
            onChanged: onGoalTimeChanged,
          ),
          if (goalResult != null) ...[
            const SizedBox(height: 8),
            Text(
              paceMode == PaceActivityMode.rowing
                  ? 'Required split: ${formatPace(goalResult!.split500Minutes)} /500m • ${formatPace(goalResult!.perKmMinutes)} min/km'
                  : 'Required pace: ${formatPace(goalResult!.perKmMinutes)} min/km • ${formatPace(goalResult!.perMiMinutes)} min/mi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: _PaceCheckpointBarChart(
                checkpoints: goalResult!.checkpoints,
                accent: theme.accent,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final cp in goalResult!.checkpoints)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: panelBg.withAlpha(216),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: panelBorder.withAlpha(160)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Text(
                        '${cp.label} ${formatDurationMinutes(cp.minutes)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              emptyGoalText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaceCheckpointBarChart extends StatelessWidget {
  final List<PaceCheckpoint> checkpoints;
  final Color accent;
  final Color textColor;

  const _PaceCheckpointBarChart({
    required this.checkpoints,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) return const SizedBox.shrink();
    final maxMinutes = checkpoints
        .map((cp) => cp.minutes)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final cp in checkpoints)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cp.label.split('•').first.trim(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxMinutes <= 0
                            ? 0
                            : (cp.minutes / maxMinutes),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                accent.withAlpha(170),
                                accent.withAlpha(105),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
