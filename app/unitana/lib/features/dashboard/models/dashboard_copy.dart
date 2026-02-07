import 'package:flutter/material.dart';

import '../../../l10n/dashboard_localizations.dart';
import 'jet_lag_planner.dart';

class DashboardCopy {
  const DashboardCopy._();

  static String weatherTitle(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.weather.title', fallback: 'Weather');
  static String refreshWeatherTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.tooltip.refresh', fallback: 'Refresh weather');
  static String closeWeatherTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.tooltip.close', fallback: 'Close weather');
  static String destinationLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.section.destination', fallback: 'Destination');
  static String homeLabel(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.weather.section.home', fallback: 'Home');

  static String closeToolTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.tooltip.close', fallback: 'Close tool');
  static String editValueLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.input.editValue', fallback: 'Edit Value');
  static String historyTitle(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.history.title', fallback: 'History');
  static String clearCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.history.clear', fallback: 'Clear');
  static String clearHistoryTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.history.clearTitle', fallback: 'Clear history?');
  static String clearHistoryMessage(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.history.clearMessage',
        fallback: 'Remove the last 10 conversions for this tool.',
      );
  static String historyCopyHint(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.history.copyHint',
        fallback: 'tap copies result; long-press copies input',
      );
  static String historyClearedNotice(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.history.cleared', fallback: 'History cleared');
  static String clearHistoryButtonLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.history.clearButton', fallback: 'Clear History');
  static String swapCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.cta.swap', fallback: 'Swap');
  static String addWidgetCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.cta.addWidget', fallback: '+ Add Widget');

  static String timeFromZoneTitle(
    BuildContext context, {
    required bool isJetLagTool,
  }) {
    final key = isJetLagTool
        ? 'dashboard.time.fromZone.jetLag'
        : 'dashboard.time.fromZone.standard';
    final fallback = isJetLagTool ? 'Home Time Zone' : 'From Time Zone';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String timeToZoneTitle(
    BuildContext context, {
    required bool isJetLagTool,
  }) {
    final key = isJetLagTool
        ? 'dashboard.time.toZone.jetLag'
        : 'dashboard.time.toZone.standard';
    final fallback = isJetLagTool ? 'Destination Time Zone' : 'To Time Zone';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String convertLocalTimeTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.converter.title', fallback: 'Convert Local Time');
  static String convertLocalTimeHelper(
    BuildContext context,
    String fromDisplayLabel,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.time.converter.helper',
    params: <String, String>{'fromDisplayLabel': fromDisplayLabel},
    fallback: 'Enter as YYYY-MM-DD HH:MM in $fromDisplayLabel',
  );
  static String convertTimeCta(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.converter.cta', fallback: 'Convert Time');

  static String factsTitle(BuildContext context, {required bool isJetLagTool}) {
    final key = isJetLagTool
        ? 'dashboard.jetLag.facts.title'
        : 'dashboard.time.currentClocks.title';
    final fallback = isJetLagTool ? 'Travel Facts' : 'Current Clocks';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String jetLagPlanTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.title', fallback: 'Jet Lag Plan');
  static String quickTipsTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.tips.title', fallback: 'Quick Tips');
  static String callWindowsTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.callWindows.title', fallback: 'Call Windows');
  static String showCallWindowsCta(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.jetLag.callWindows.cta.show',
        fallback: 'Show call windows',
      );
  static String overlapIntro(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.jetLag.callWindows.intro',
        fallback: 'Quick check before scheduling calls:',
      );

  static String updating(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.freshness.updating', fallback: 'Updating…');
  static String notUpdated(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.freshness.notUpdated', fallback: 'Not updated');
  static String updated(BuildContext context, String age) =>
      DashboardLocalizations.of(context).text(
        'dashboard.freshness.updated',
        params: <String, String>{'age': age},
        fallback: 'Updated $age',
      );
  static String stale(BuildContext context, String age) =>
      DashboardLocalizations.of(context).text(
        'dashboard.freshness.stale',
        params: <String, String>{'age': age},
        fallback: 'Stale ($age)',
      );

  static String weatherStaleSuffix({required bool isStale}) =>
      isStale ? ' (stale)' : '';

  static String currencyStaleRetryNow(BuildContext context, String age) =>
      DashboardLocalizations.of(context).text(
        'dashboard.currency.stale.retryNow',
        params: <String, String>{'age': age},
        fallback: 'Rates are stale (last error $age). You can retry now.',
      );
  static String currencyStaleRetrySoon(BuildContext context, String age) =>
      DashboardLocalizations.of(context).text(
        'dashboard.currency.stale.retrySoon',
        params: <String, String>{'age': age},
        fallback: 'Rates are stale (last error $age). Retrying in a moment.',
      );
  static String currencyUsingCachedRates(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.currency.stale.cached',
        fallback: 'Using cached rates. They may be stale.',
      );
  static String retryRatesCta(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.currency.cta.retry', fallback: 'Retry rates');
  static String refreshingRatesNotice(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.currency.notice.refreshing',
        fallback: 'Refreshing rates…',
      );
  static String refreshRatesFailedNotice(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.currency.notice.refreshFailed',
        fallback: 'Could not refresh rates',
      );

  static String dateImpactTitleCase(String dateImpactRaw) {
    return switch (dateImpactRaw.toLowerCase()) {
      'next day' => 'Next Day',
      'same day' => 'Same Day',
      'previous day' => 'Previous Day',
      _ => dateImpactRaw,
    };
  }

  static List<String> jetLagTips({
    required JetLagPlan plan,
    required String destinationLabel,
  }) {
    if (plan.isNoShift) {
      return const <String>[
        'Little or no reset needed. Keep your usual sleep schedule tonight.',
        'Morning light and hydration help you stay on track.',
      ];
    }

    const mild = <String>[
      'Keep caffeine to the morning and skip late boosts.',
      'Get morning daylight soon after arrival.',
    ];
    const moderate = <String>[
      'Move meal times toward local time to help your body clock.',
      'If needed, take one short nap (20-30 min).',
    ];
    const high = <String>[
      'If you can, shift your schedule one night before travel.',
      'Use bright light in the morning and dim light at night.',
    ];

    switch (plan.band) {
      case JetLagBand.extreme:
      case JetLagBand.high:
        return <String>[
          'Big shift for $destinationLabel. Keep tonight simple and steady.',
          ...high,
          ...moderate,
          ...mild,
        ];
      case JetLagBand.moderate:
        return <String>[
          'Moderate shift for $destinationLabel. Small daily steps work best.',
          ...moderate,
          ...mild,
        ];
      case JetLagBand.mild:
        return <String>[
          'Small shift for $destinationLabel. You should settle quickly.',
          ...mild,
        ];
      case JetLagBand.minimal:
        return const <String>[
          'Very small shift. Keep your routine steady.',
          'Morning light and hydration are usually enough.',
        ];
    }
  }
}
