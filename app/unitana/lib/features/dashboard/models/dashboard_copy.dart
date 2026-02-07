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

  static String tipBillAmountLabel(BuildContext context, String currencyCode) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tip.billAmountLabel',
        params: <String, String>{'currencyCode': currencyCode},
        fallback: 'Bill Amount ($currencyCode)',
      );
  static String tipSplitLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tip.splitLabel', fallback: 'Split');
  static String tipRoundingLabel(BuildContext context, String mode) {
    final (key, fallback) = switch (mode) {
      'none' => ('dashboard.tip.round.none', 'No round'),
      'nearest' => ('dashboard.tip.round.nearest', 'Nearest'),
      'up' => ('dashboard.tip.round.up', 'Round up'),
      'down' => ('dashboard.tip.round.down', 'Round down'),
      _ => ('dashboard.tip.round.none', 'No round'),
    };
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String tipInvalidAmount(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tip.invalidAmount',
        fallback: 'Enter a valid amount to calculate tip.',
      );
  static String tipLineLabel(BuildContext context, int percent) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tip.line.tip',
        params: <String, String>{'percent': '$percent'},
        fallback: 'Tip ($percent%)',
      );
  static String tipTotalLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tip.line.total', fallback: 'Total');
  static String tipPerPersonLabel(BuildContext context, int count) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tip.line.perPerson',
        params: <String, String>{'count': '$count'},
        fallback: 'Per person ($count)',
      );
  static String tipRoundingAdjustment(
    BuildContext context, {
    required String sign,
    required String deltaAmount,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.tip.roundingAdjustment',
    params: <String, String>{'sign': sign, 'deltaAmount': deltaAmount},
    fallback: 'Rounding adjustment: $sign$deltaAmount',
  );

  static String taxAmountLabel(
    BuildContext context, {
    required bool isAddOn,
    required String currencyCode,
  }) {
    final key = isAddOn
        ? 'dashboard.tax.subtotalLabel'
        : 'dashboard.tax.totalLabel';
    final fallback = isAddOn
        ? 'Subtotal ($currencyCode)'
        : 'Total ($currencyCode)';
    return DashboardLocalizations.of(context).text(
      key,
      params: <String, String>{'currencyCode': currencyCode},
      fallback: fallback,
    );
  }

  static String taxModeAddOn(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tax.mode.addOn', fallback: 'Add-on tax');
  static String taxModeInclusive(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tax.mode.inclusive', fallback: 'VAT inclusive');
  static String taxInvalidAmount(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tax.invalidAmount',
        fallback: 'Enter a valid amount to calculate tax.',
      );
  static String taxSubtotalLine(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tax.line.subtotal', fallback: 'Subtotal');
  static String taxLineLabel(BuildContext context, int percent) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tax.line.tax',
        params: <String, String>{'percent': '$percent'},
        fallback: 'Tax ($percent%)',
      );
  static String taxTotalLine(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tax.line.total', fallback: 'Total');
  static String taxModeHelp(BuildContext context, {required bool isAddOn}) {
    final key = isAddOn
        ? 'dashboard.tax.mode.help.addOn'
        : 'dashboard.tax.mode.help.inclusive';
    final fallback = isAddOn
        ? 'Mode: add tax on top of subtotal'
        : 'Mode: tax already included in total';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String unitPriceCompareInvalid(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareInvalid',
        fallback: 'Comparison needs valid values in the same unit family.',
      );
  static String unitPriceCompareA(BuildContext context, String percent) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareA',
        params: <String, String>{'percent': percent},
        fallback: 'Product A is cheaper by $percent%.',
      );
  static String unitPriceCompareB(BuildContext context, String percent) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareB',
        params: <String, String>{'percent': percent},
        fallback: 'Product B is cheaper by $percent%.',
      );
  static String unitPriceCompareEqual(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareEqual',
        fallback: 'Products are equal in normalized unit price.',
      );
  static String unitPriceLabelPrice(
    BuildContext context,
    String currencyCode,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.unitPrice.label.price',
    params: <String, String>{'currencyCode': currencyCode},
    fallback: 'Price ($currencyCode)',
  );
  static String unitPriceLabelQuantity(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.unitPrice.label.quantity', fallback: 'Quantity');
  static String unitPriceProductTitle(
    BuildContext context, {
    required bool isA,
  }) {
    final key = isA
        ? 'dashboard.unitPrice.title.productA'
        : 'dashboard.unitPrice.title.productB';
    final fallback = isA ? 'Product A' : 'Product B';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String unitPriceCompareToggle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareToggle',
        fallback: 'Compare with Product B',
      );
  static String unitPriceInvalidProductA(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.invalidProductA',
        fallback: 'Enter valid price and quantity for Product A.',
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
