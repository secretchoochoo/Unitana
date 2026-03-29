import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/dashboard_session_controller.dart';

@immutable
class ToolTimeSurfaceTheme {
  final Color accent;
  final Color panelBg;
  final Color panelBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color headingTone;
  final Color infoTone;
  final Color warningTone;
  final Color successTone;
  final Color dangerTone;

  const ToolTimeSurfaceTheme({
    required this.accent,
    required this.panelBg,
    required this.panelBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.headingTone,
    required this.infoTone,
    required this.warningTone,
    required this.successTone,
    required this.dangerTone,
  });
}

class ToolTimeSurface extends StatelessWidget {
  final String toolId;
  final String fromZoneTitle;
  final String fromDisplayLabel;
  final String toZoneTitle;
  final String toDisplayLabel;
  final bool showAddWidget;
  final String addWidgetLabel;
  final String swapLabel;
  final ToolTimeSurfaceTheme theme;
  final VoidCallback onPickFromZone;
  final VoidCallback onPickToZone;
  final VoidCallback onSwapZones;
  final VoidCallback? onAddWidget;
  final List<Widget> sections;

  const ToolTimeSurface({
    super.key,
    required this.toolId,
    required this.fromZoneTitle,
    required this.fromDisplayLabel,
    required this.toZoneTitle,
    required this.toDisplayLabel,
    required this.showAddWidget,
    required this.addWidgetLabel,
    required this.swapLabel,
    required this.theme,
    required this.onPickFromZone,
    required this.onPickToZone,
    required this.onSwapZones,
    required this.onAddWidget,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('tool_time_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('tool_time_from_zone'),
                dense: true,
                title: Text(fromZoneTitle),
                subtitle: Text(fromDisplayLabel),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: onPickFromZone,
              ),
              Divider(color: theme.textMuted.withAlpha(120), height: 1),
              ListTile(
                key: const ValueKey('tool_time_to_zone'),
                dense: true,
                title: Text(toZoneTitle),
                subtitle: Text(toDisplayLabel),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: onPickToZone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          key: const ValueKey('tool_time_action_row'),
          children: [
            Expanded(
              child: showAddWidget && onAddWidget != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('tool_add_widget_time'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: theme.panelBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onAddWidget,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: theme.accent,
                        ),
                        label: Text(
                          addWidgetLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.accent,
                              ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  key: const ValueKey('tool_time_swap_zones'),
                  onPressed: onSwapZones,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(swapLabel),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          sections[i],
        ],
      ],
    );
  }
}

class ToolTimeFactsCard extends StatelessWidget {
  final String title;
  final bool showDualAnalogClocks;
  final String fromCity;
  final String toCity;
  final String fromPrefix;
  final String toPrefix;
  final DateTime fromLocalTime;
  final DateTime toLocalTime;
  final String fromDigitalHud;
  final String toDigitalHud;
  final String fromClockLine;
  final String toClockLine;
  final String offsetLabel;
  final String offsetValue;
  final String? dateLabel;
  final String? dateValue;
  final String? flightLabel;
  final String? flightValue;
  final ToolTimeSurfaceTheme theme;

  const ToolTimeFactsCard({
    super.key,
    required this.title,
    required this.showDualAnalogClocks,
    required this.fromCity,
    required this.toCity,
    required this.fromPrefix,
    required this.toPrefix,
    required this.fromLocalTime,
    required this.toLocalTime,
    required this.fromDigitalHud,
    required this.toDigitalHud,
    required this.fromClockLine,
    required this.toClockLine,
    required this.offsetLabel,
    required this.offsetValue,
    required this.dateLabel,
    required this.dateValue,
    required this.flightLabel,
    required this.flightValue,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Widget factsMetaLine({
      required String label,
      required String value,
      Color? labelColor,
      Color? valueColor,
      bool italicValue = false,
      bool breakValueLine = false,
    }) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: breakValueLine ? '$label\n' : '$label ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor ?? theme.textMuted.withAlpha(222),
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor ?? theme.textPrimary,
                fontWeight: FontWeight.w700,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey('tool_time_now_card'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.infoTone,
            ),
          ),
          if (showDualAnalogClocks) ...[
            const SizedBox(height: 10),
            Row(
              key: const ValueKey('tool_time_dual_analog_row'),
              children: [
                Expanded(
                  child: _TimeAnalogClockFace(
                    key: const ValueKey('tool_time_analog_clock_home'),
                    cityLabel: fromCity,
                    flagPrefix: fromPrefix,
                    localTime: fromLocalTime,
                    digitalHud: fromDigitalHud,
                    accentColor: theme.infoTone.withAlpha(232),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeAnalogClockFace(
                    key: const ValueKey('tool_time_analog_clock_destination'),
                    cityLabel: toCity,
                    flagPrefix: toPrefix,
                    localTime: toLocalTime,
                    digitalHud: toDigitalHud,
                    accentColor: theme.warningTone.withAlpha(232),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$fromPrefix$fromCity:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' $fromClockLine',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$toPrefix$toCity:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' $toClockLine',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          factsMetaLine(
            label: offsetLabel,
            value: offsetValue,
            breakValueLine: dateLabel != null,
          ),
          if (dateLabel != null && dateValue != null) ...[
            const SizedBox(height: 4),
            factsMetaLine(label: dateLabel!, value: dateValue!),
          ],
          if (flightLabel != null && flightValue != null) ...[
            const SizedBox(height: 4),
            factsMetaLine(
              label: flightLabel!,
              value: flightValue!,
              labelColor: theme.infoTone.withAlpha(220),
              valueColor: theme.infoTone.withAlpha(236),
              italicValue: true,
            ),
          ],
        ],
      ),
    );
  }
}

class ToolJetLagPlannerCard extends StatelessWidget {
  final String title;
  final String offsetLabel;
  final String bandLabelTitle;
  final String dailyShiftLabelTitle;
  final String deltaMetricLabel;
  final String bandLabel;
  final int adjustmentDays;
  final String dailyShiftLabel;
  final String bedtimeButtonLabel;
  final String wakeButtonLabel;
  final String tonightTargetLabel;
  final String tonightScheduleText;
  final String? baselineLabel;
  final String? baselineScheduleText;
  final String quickTipsTitle;
  final String tipText;
  final int tipKeySuffix;
  final String callWindowsTitle;
  final bool showOverlapHints;
  final bool showOverlapDetails;
  final bool showOverlapExpandCta;
  final String showCallWindowsLabel;
  final String overlapIntro;
  final InlineSpan? overlapMorningLine;
  final InlineSpan? overlapEveningLine;
  final ToolTimeSurfaceTheme theme;
  final VoidCallback onPickBedtime;
  final VoidCallback onPickWakeTime;
  final VoidCallback? onExpandOverlap;

  const ToolJetLagPlannerCard({
    super.key,
    required this.title,
    required this.offsetLabel,
    required this.bandLabelTitle,
    required this.dailyShiftLabelTitle,
    required this.deltaMetricLabel,
    required this.bandLabel,
    required this.adjustmentDays,
    required this.dailyShiftLabel,
    required this.bedtimeButtonLabel,
    required this.wakeButtonLabel,
    required this.tonightTargetLabel,
    required this.tonightScheduleText,
    required this.baselineLabel,
    required this.baselineScheduleText,
    required this.quickTipsTitle,
    required this.tipText,
    required this.tipKeySuffix,
    required this.callWindowsTitle,
    required this.showOverlapHints,
    required this.showOverlapDetails,
    required this.showOverlapExpandCta,
    required this.showCallWindowsLabel,
    required this.overlapIntro,
    required this.overlapMorningLine,
    required this.overlapEveningLine,
    required this.theme,
    required this.onPickBedtime,
    required this.onPickWakeTime,
    required this.onExpandOverlap,
  });

  @override
  Widget build(BuildContext context) {
    Widget planMetaLine({
      required String label,
      required String value,
      Color? labelColor,
      Color? valueColor,
      bool italicValue = false,
    }) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor ?? theme.warningTone.withAlpha(220),
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor ?? theme.textPrimary,
                fontWeight: FontWeight.w700,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey('tool_time_planner_card'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.warningTone,
            ),
          ),
          const SizedBox(height: 8),
          planMetaLine(label: offsetLabel, value: deltaMetricLabel),
          const SizedBox(height: 4),
          planMetaLine(
            label: bandLabelTitle,
            value: '$bandLabel · ~$adjustmentDays days',
          ),
          const SizedBox(height: 4),
          planMetaLine(label: dailyShiftLabelTitle, value: dailyShiftLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('tool_jetlag_bedtime_button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onPickBedtime,
                  child: Text(
                    bedtimeButtonLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('tool_jetlag_wake_button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onPickWakeTime,
                  child: Text(
                    wakeButtonLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            key: const ValueKey('tool_jetlag_personalized_schedule'),
            TextSpan(
              children: [
                TextSpan(
                  text: tonightTargetLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.warningTone.withAlpha(218),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: tonightScheduleText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.textPrimary.withAlpha(240),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (baselineLabel != null && baselineScheduleText != null) ...[
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: baselineLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.warningTone.withAlpha(218),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: baselineScheduleText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.textPrimary.withAlpha(240),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '💡 $quickTipsTitle',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.warningTone,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: Align(
              alignment: Alignment.topLeft,
              child: AnimatedSwitcher(
                key: const ValueKey('tool_jetlag_tip_rotator'),
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  tipText,
                  key: ValueKey('tool_jetlag_tip_text_$tipKeySuffix'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.textMuted.withAlpha(236),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (showOverlapHints) ...[
            const SizedBox(height: 8),
            Text(
              '📞 $callWindowsTitle',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.warningTone,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            if (showOverlapExpandCta)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const ValueKey('tool_jetlag_overlap_toggle'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onExpandOverlap,
                  child: Text(showCallWindowsLabel),
                ),
              ),
            if (showOverlapDetails)
              Column(
                key: const ValueKey('tool_jetlag_overlap_panel'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overlapIntro,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.textMuted.withAlpha(232),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (overlapMorningLine != null)
                    Text.rich(overlapMorningLine!),
                  if (overlapEveningLine != null) ...[
                    const SizedBox(height: 2),
                    Text.rich(overlapEveningLine!),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class ToolWorldTimeMapCard extends StatelessWidget {
  final String title;
  final String summary;
  final String fromCity;
  final String toCity;
  final double fromOffsetHours;
  final double toOffsetHours;
  final ToolTimeSurfaceTheme theme;

  const ToolWorldTimeMapCard({
    super.key,
    required this.title,
    required this.summary,
    required this.fromCity,
    required this.toCity,
    required this.fromOffsetHours,
    required this.toOffsetHours,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('tool_time_world_map_card'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.headingTone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _WorldTimeZoneBandMap(
            fromCity: fromCity,
            toCity: toCity,
            fromOffsetHours: fromOffsetHours,
            toOffsetHours: toOffsetHours,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class ToolTimeConverterSection extends StatelessWidget {
  final String toolId;
  final String title;
  final String helperText;
  final String inputHint;
  final String convertLabel;
  final String resultPlaceholderInput;
  final String resultPlaceholderOutput;
  final TextEditingController controller;
  final String? resultLine;
  final ToolTimeSurfaceTheme theme;
  final VoidCallback onRunConversion;

  const ToolTimeConverterSection({
    super.key,
    required this.toolId,
    required this.title,
    required this.helperText,
    required this.inputHint,
    required this.convertLabel,
    required this.resultPlaceholderInput,
    required this.resultPlaceholderOutput,
    required this.controller,
    required this.resultLine,
    required this.theme,
    required this.onRunConversion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('tool_time_converter_card'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.headingTone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('tool_time_convert_input'),
            controller: controller,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(hintText: inputHint),
            onSubmitted: (_) => onRunConversion(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('tool_time_convert_run'),
              onPressed: onRunConversion,
              child: Text(convertLabel),
            ),
          ),
          const SizedBox(height: 10),
          _TimeResultCard(
            toolId: toolId,
            line: resultLine,
            theme: theme,
            placeholderInput: resultPlaceholderInput,
            placeholderOutput: resultPlaceholderOutput,
          ),
        ],
      ),
    );
  }
}

class ToolTimeHistorySection extends StatelessWidget {
  final List<ConversionRecord> history;
  final String historyTitle;
  final String clearLabel;
  final String emptyHistoryLabel;
  final ToolTimeSurfaceTheme theme;
  final VoidCallback? onClear;

  const ToolTimeHistorySection({
    super.key,
    required this.history,
    required this.historyTitle,
    required this.clearLabel,
    required this.emptyHistoryLabel,
    required this.theme,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                historyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.headingTone,
                ),
              ),
              OutlinedButton(
                key: const ValueKey('tool_time_history_clear'),
                onPressed: history.isEmpty ? null : onClear,
                child: Text(clearLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          key: const ValueKey('tool_time_history_container'),
          decoration: BoxDecoration(
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.panelBorder),
          ),
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: _TimeEmptyHistory(label: emptyHistoryLabel),
                )
              : ListView.builder(
                  key: const ValueKey('tool_time_history_list'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return ListTile(
                      dense: true,
                      title: Text(record.outputLabel),
                      subtitle: Text(record.inputLabel),
                      trailing: Text(
                        record.timestamp.toLocal().toIso8601String().substring(
                          11,
                          16,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme.textMuted.withAlpha(200),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TimeResultCard extends StatelessWidget {
  final String toolId;
  final String? line;
  final ToolTimeSurfaceTheme theme;
  final String placeholderInput;
  final String placeholderOutput;

  const _TimeResultCard({
    required this.toolId,
    required this.line,
    required this.theme,
    required this.placeholderInput,
    required this.placeholderOutput,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = line;
    String input;
    String output;
    if (resolved == null || resolved.trim().isEmpty) {
      input = placeholderInput;
      output = placeholderOutput;
    } else if (resolved.contains('→')) {
      final parts = resolved.split('→');
      input = parts.first.trim();
      output = parts.sublist(1).join('→').trim();
    } else {
      input = resolved.trim();
      output = '';
    }

    return Container(
      key: ValueKey('tool_result_$toolId'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            color: theme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: '>',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.successTone,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: ' $input '),
            TextSpan(
              text: '→',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: ' $output'),
          ],
        ),
      ),
    );
  }
}

class _TimeEmptyHistory extends StatelessWidget {
  final String label;

  const _TimeEmptyHistory({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(225),
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _TimeAnalogClockFace extends StatelessWidget {
  final String cityLabel;
  final String flagPrefix;
  final DateTime localTime;
  final String digitalHud;
  final Color accentColor;
  final ToolTimeSurfaceTheme theme;

  const _TimeAnalogClockFace({
    super.key,
    required this.cityLabel,
    required this.flagPrefix,
    required this.localTime,
    required this.digitalHud,
    required this.accentColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$flagPrefix$cityLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.panelBg.withAlpha(210),
                    border: Border.all(color: theme.panelBorder, width: 1.2),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _TimeAnalogClockPainter(
                    localTime: localTime,
                    accentColor: accentColor,
                    tickColor: theme.textMuted,
                    handColor: theme.textPrimary,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    key: ValueKey('tool_time_analog_hud_$cityLabel'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.panelBg.withAlpha(210),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color:
                            (isLight
                                    ? Theme.of(context).colorScheme.outline
                                    : accentColor)
                                .withAlpha(165),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      digitalHud,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeAnalogClockPainter extends CustomPainter {
  final DateTime localTime;
  final Color accentColor;
  final Color tickColor;
  final Color handColor;

  const _TimeAnalogClockPainter({
    required this.localTime,
    required this.accentColor,
    required this.tickColor,
    required this.handColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final tickPaint = Paint()
      ..color = tickColor.withAlpha(150)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    for (var i = 0; i < 12; i++) {
      final angle = (math.pi * 2 * (i / 12)) - (math.pi / 2);
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 16);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final minutes = localTime.minute + (localTime.second / 60);
    final hours = (localTime.hour % 12) + (minutes / 60);
    final minuteAngle = (math.pi * 2 * (minutes / 60)) - (math.pi / 2);
    final hourAngle = (math.pi * 2 * (hours / 12)) - (math.pi / 2);

    final hourHandPaint = Paint()
      ..color = handColor.withAlpha(242)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final minuteHandPaint = Paint()
      ..color = accentColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1;

    final hourEnd =
        center +
        Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * 0.45);
    final minuteEnd =
        center +
        Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * 0.64);
    canvas.drawLine(center, hourEnd, hourHandPaint);
    canvas.drawLine(center, minuteEnd, minuteHandPaint);
    canvas.drawCircle(center, 3.2, Paint()..color = accentColor.withAlpha(232));
  }

  @override
  bool shouldRepaint(covariant _TimeAnalogClockPainter oldDelegate) {
    return oldDelegate.localTime.minute != localTime.minute ||
        oldDelegate.localTime.hour != localTime.hour ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.handColor != handColor;
  }
}

class _WorldTimeZoneBandMap extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final double fromOffsetHours;
  final double toOffsetHours;
  final ToolTimeSurfaceTheme theme;

  const _WorldTimeZoneBandMap({
    required this.fromCity,
    required this.toCity,
    required this.fromOffsetHours,
    required this.toOffsetHours,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bands = List<int>.generate(27, (index) => index - 12);

    int nearestBand(double offset) {
      var best = bands.first;
      var bestDiff = (bands.first - offset).abs();
      for (final band in bands.skip(1)) {
        final diff = (band - offset).abs();
        if (diff < bestDiff) {
          best = band;
          bestDiff = diff;
        }
      }
      return best;
    }

    final fromBand = nearestBand(fromOffsetHours);
    final toBand = nearestBand(toOffsetHours);

    Color bandColor(int band) {
      final isHome = band == fromBand;
      final isDest = band == toBand;
      if (isHome && isDest) {
        return Color.lerp(
          theme.infoTone,
          theme.dangerTone,
          0.5,
        )!.withAlpha(185);
      }
      if (isHome) return theme.infoTone.withAlpha(195);
      if (isDest) return theme.dangerTone.withAlpha(195);
      return theme.panelBg.withAlpha(170);
    }

    Widget legendPill({
      required String city,
      required double offset,
      required Color tone,
      required TextAlign align,
    }) {
      final offsetText =
          'UTC${offset >= 0 ? '+' : ''}${offset.toStringAsFixed(1)}';
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.panelBg.withAlpha(210),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tone.withAlpha(170)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: Column(
            crossAxisAlignment: align == TextAlign.right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                offsetText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: theme.textMuted.withAlpha(230),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('tool_time_world_map_bands'),
      height: 150,
      decoration: BoxDecoration(
        color: theme.panelBg.withAlpha(210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.panelBorder),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.5,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        theme.textMuted.withAlpha(210),
                        BlendMode.modulate,
                      ),
                      child: Image.asset(
                        'assets/maps/world_outline.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.06, -0.08),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WorldTimeBackdropPainter(
                        color: theme.textMuted.withAlpha(60),
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final band in bands)
                      Expanded(
                        child: Tooltip(
                          message:
                              'UTC${band >= 0 ? '+' : ''}$band${band == fromBand ? ' • Home' : ''}${band == toBand ? ' • Destination' : ''}',
                          child: Container(
                            decoration: BoxDecoration(
                              color: bandColor(band),
                              border: Border(
                                right: BorderSide(
                                  color: theme.textMuted.withAlpha(78),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: legendPill(
                    city: fromCity,
                    offset: fromOffsetHours,
                    tone: theme.infoTone,
                    align: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: legendPill(
                    city: toCity,
                    offset: toOffsetHours,
                    tone: theme.dangerTone,
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldTimeBackdropPainter extends CustomPainter {
  final Color color;

  const _WorldTimeBackdropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final gridStroke = Paint()
      ..color = color.withAlpha(56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    final latitudeStroke = Paint()
      ..color = color.withAlpha(78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;

    for (var i = 1; i <= 5; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridStroke);
    }
    for (var i = 1; i <= 23; i++) {
      final x = size.width * (i / 24);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridStroke);
    }
    final equatorY = size.height * 0.5;
    final tropicNorthY = size.height * (1 / 3);
    final tropicSouthY = size.height * (2 / 3);
    final polarSouthY = size.height * 0.82;
    canvas.drawLine(
      Offset(0, equatorY),
      Offset(size.width, equatorY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, tropicNorthY),
      Offset(size.width, tropicNorthY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, tropicSouthY),
      Offset(size.width, tropicSouthY),
      latitudeStroke,
    );
    canvas.drawLine(
      Offset(0, polarSouthY),
      Offset(size.width, polarSouthY),
      latitudeStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldTimeBackdropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
