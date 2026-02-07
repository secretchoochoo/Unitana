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
  static String copiedNotice(BuildContext context, String label) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.notice.copied',
        params: <String, String>{'label': label},
        fallback: 'Copied $label',
      );
  static String addedWidgetNotice(BuildContext context, String title) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.notice.addedWidget',
        params: <String, String>{'title': title},
        fallback: 'Added $title to dashboard',
      );
  static String duplicateWidgetNotice(BuildContext context, String title) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.notice.duplicateWidget',
        params: <String, String>{'title': title},
        fallback: '$title is already on your dashboard',
      );
  static String addWidgetFailedNotice(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.notice.addWidgetFailed',
        fallback: 'Could not add widget',
      );
  static String swapCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.cta.swap', fallback: 'Swap');
  static String addWidgetCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.cta.addWidget', fallback: '+ Add Widget');
  static String lookupFromLabel(BuildContext context, String value) =>
      DashboardLocalizations.of(context).text(
        'dashboard.lookup.from',
        params: <String, String>{'value': value},
        fallback: 'From: $value',
      );
  static String lookupToLabel(BuildContext context, String value) =>
      DashboardLocalizations.of(context).text(
        'dashboard.lookup.to',
        params: <String, String>{'value': value},
        fallback: 'To: $value',
      );
  static String lookupSizeLabel(BuildContext context, String value) =>
      DashboardLocalizations.of(context).text(
        'dashboard.lookup.size',
        params: <String, String>{'value': value},
        fallback: 'Size: $value',
      );
  static String lookupResetDefaults(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.lookup.resetDefaults', fallback: 'Reset Defaults');
  static String lookupSizeMatrix(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.lookup.sizeMatrix', fallback: 'Size Matrix');
  static String lookupMatrixHelp(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.lookup.matrixHelp',
        fallback:
            'Selected row centered when possible. Tap a value cell to copy.',
      );
  static String lookupApproximate(BuildContext context, String note) =>
      DashboardLocalizations.of(context).text(
        'dashboard.lookup.approximate',
        params: <String, String>{'note': note},
        fallback: 'Approximate: $note',
      );

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
  static String timeDirection({
    required BuildContext context,
    required JetLagDirection direction,
  }) {
    switch (direction) {
      case JetLagDirection.none:
        return DashboardLocalizations.of(
          context,
        ).text('dashboard.time.direction.sameZone', fallback: 'Same zone');
      case JetLagDirection.eastbound:
        return DashboardLocalizations.of(
          context,
        ).text('dashboard.time.direction.eastbound', fallback: 'Eastbound');
      case JetLagDirection.westbound:
        return DashboardLocalizations.of(
          context,
        ).text('dashboard.time.direction.westbound', fallback: 'Westbound');
    }
  }

  static String timeFactsOffsetLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.facts.offset', fallback: 'Offset:');
  static String timeFactsDateLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.facts.date', fallback: 'Date:');
  static String timeFactsFlightLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.facts.flight', fallback: 'Flight:');
  static String jetLagBandLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.band', fallback: 'Band:');
  static String jetLagDailyShiftLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.dailyShift', fallback: 'Daily Shift:');
  static String jetLagTonightTargetLabel(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.jetLag.plan.tonightTarget',
        fallback: 'Tonight Target: ',
      );
  static String jetLagBaselineLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.baseline', fallback: 'Baseline: ');
  static String jetLagSleepPrefix(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.sleep', fallback: 'Sleep ');
  static String jetLagWakePrefix(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.jetLag.plan.wake', fallback: ' · Wake ');
  static String jetLagBedtimeButton(BuildContext context, String time) =>
      DashboardLocalizations.of(context).text(
        'dashboard.jetLag.plan.bedtimeButton',
        params: <String, String>{'time': time},
        fallback: 'Bedtime: $time',
      );
  static String jetLagWakeButton(BuildContext context, String time) =>
      DashboardLocalizations.of(context).text(
        'dashboard.jetLag.plan.wakeButton',
        params: <String, String>{'time': time},
        fallback: 'Wake: $time',
      );
  static String jetLagCallWindowMorning(
    BuildContext context, {
    required String toCity,
    required String overlapMorning,
    required String fromCity,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.jetLag.callWindows.morning',
    params: <String, String>{
      'destTime': '09:00',
      'toCity': toCity,
      'homeTime': overlapMorning,
      'fromCity': fromCity,
    },
    fallback: '09:00 in $toCity = $overlapMorning in $fromCity',
  );
  static String jetLagCallWindowEvening(
    BuildContext context, {
    required String toCity,
    required String overlapEvening,
    required String fromCity,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.jetLag.callWindows.evening',
    params: <String, String>{
      'destTime': '20:00',
      'toCity': toCity,
      'homeTime': overlapEvening,
      'fromCity': fromCity,
    },
    fallback: '20:00 in $toCity = $overlapEvening in $fromCity',
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
  static String dashboardComingSoon(BuildContext context, String label) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.comingSoon',
        params: <String, String>{'label': label},
        fallback: '$label: coming soon',
      );
  static String dashboardProfileUpdated(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.profileUpdated', fallback: 'Profile updated');
  static String dashboardProfileCreated(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.profileCreated', fallback: 'Profile created');
  static String dashboardClosePanelTooltip(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.closePanelTooltip',
        fallback: 'Close this panel',
      );
  static String dashboardUpdated(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.updated', fallback: 'Dashboard updated');
  static String dashboardProfileNameFallback(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.profileNameFallback', fallback: 'My Places');
  static String dashboardOpenToolsTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.tooltip.openTools', fallback: 'Open tools');
  static String dashboardOpenMenuTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.tooltip.openMenu', fallback: 'Open menu');
  static String dashboardRefreshDataTooltip(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.tooltip.refreshData',
        fallback: 'Refresh data',
      );
  static String dashboardMenuProfiles(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.menu.profiles', fallback: 'Profiles');
  static String dashboardMenuSettings(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.menu.settings', fallback: 'Settings');
  static String dashboardMenuEditWidgets(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.menu.editWidgets', fallback: 'Edit Widgets');
  static String dashboardMenuResetDefaults(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.menu.resetDefaults',
        fallback: 'Reset Dashboard Defaults',
      );
  static String dashboardMenuDeveloperTools(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.menu.developerTools',
        fallback: 'Developer Tools',
      );
  static String dashboardEditCancel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.edit.cancel', fallback: 'Cancel');
  static String dashboardEditDone(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.edit.done', fallback: 'Done');
  static String dashboardResetDefaultsMessage(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.dashboard.resetDefaults.message',
    fallback:
        'This removes any widgets you\'ve added and restores the default dashboard layout.',
  );
  static String dashboardResetDefaultsConfirm(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.resetDefaults.confirm', fallback: 'Reset');
  static String dashboardResetDefaultsSuccess(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.dashboard.resetDefaults.success',
        fallback: 'Dashboard reset to defaults.',
      );
  static String devtoolsWeatherTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.weather.title', fallback: 'Weather');
  static String devtoolsWeatherSourceHeading(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.weather.sourceHeading',
        fallback: 'Weather Source',
      );
  static String devtoolsWeatherSourceSummary(
    BuildContext context,
    String sourceLabel,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.sourceSummary',
    params: <String, String>{'sourceLabel': sourceLabel},
    fallback:
        'Source: $sourceLabel\nForce hero weather scenes during development',
  );
  static String devtoolsWeatherNoApiKey(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.weather.noApiKey',
        fallback: 'No API key required',
      );
  static String devtoolsWeatherRequiresApiKey(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.weather.requiresApiKey',
        fallback: 'Requires WEATHERAPI_KEY',
      );
  static String devtoolsWeatherMissingApiKey(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.weather.missingApiKey',
        fallback: 'Not configured (missing WEATHERAPI_KEY)',
      );
  static String devtoolsWeatherFreshnessNever(
    BuildContext context, {
    required String sourceShortLabel,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.freshness.never',
    params: <String, String>{'source': sourceShortLabel},
    fallback: '$sourceShortLabel: Last update: never',
  );
  static String devtoolsWeatherFreshnessUpdated(
    BuildContext context, {
    required String sourceShortLabel,
    required String age,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.freshness.updated',
    params: <String, String>{'source': sourceShortLabel, 'age': age},
    fallback: '$sourceShortLabel: Last update: $age',
  );
  static String devtoolsWeatherTimeAuto(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.weather.time.auto', fallback: 'Auto');
  static String devtoolsWeatherTimeSun(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.weather.time.sun', fallback: 'Sun');
  static String devtoolsWeatherTimeNight(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.weather.time.night', fallback: 'Night');
  static String devtoolsWeatherDefaultChoice(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.weather.defaultChoice',
        fallback: 'Default (no visual override)',
      );
  static String devtoolsClockTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.clock.title', fallback: 'Clock Override');
  static String devtoolsClockDeviceSubtitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.clock.subtitle.device',
        fallback: 'Device clock (no offset)',
      );
  static String devtoolsClockOffsetSubtitle(
    BuildContext context, {
    required String offsetText,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.clock.subtitle.offset',
    params: <String, String>{'offset': offsetText},
    fallback: 'Offset: $offsetText',
  );
  static String devtoolsClockEnableTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.clock.enableTitle',
        fallback: 'Enable clock offset',
      );
  static String devtoolsClockEnableHelp(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.clock.enableHelp',
    fallback:
        'Applies a temporary UTC offset for simulator testing and screenshots.',
  );
  static String devtoolsClockOffsetHoursLabel(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.clock.offsetHoursLabel',
        fallback: 'Offset (hours)',
      );
  static String devtoolsTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.devtools.title', fallback: 'Developer Tools');
  static String devtoolsSubtitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.subtitle',
        fallback: 'Temporary tools for development and QA',
      );
  static String devtoolsResetRestartTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.resetRestart.title',
        fallback: 'Reset and Restart',
      );
  static String devtoolsResetRestartSubtitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.devtools.resetRestart.subtitle',
        fallback: 'Restore defaults and clear cached data',
      );
  static String devtoolsSourceNoOverride(
    BuildContext context, {
    required String sourceLabel,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.source.noOverride',
    params: <String, String>{'sourceLabel': sourceLabel},
    fallback: 'Source: $sourceLabel · No override',
  );
  static String devtoolsSourceForced(
    BuildContext context, {
    required String sourceLabel,
    required String forcedLabel,
    required String suffix,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.source.forced',
    params: <String, String>{
      'sourceLabel': sourceLabel,
      'forcedLabel': forcedLabel,
      'suffix': suffix,
    },
    fallback: 'Source: $sourceLabel · Forced: $forcedLabel$suffix',
  );
  static String devtoolsNightSuffix(
    BuildContext context, {
    required bool night,
  }) => night
      ? DashboardLocalizations.of(
          context,
        ).text('dashboard.devtools.suffix.night', fallback: ' (night)')
      : DashboardLocalizations.of(
          context,
        ).text('dashboard.devtools.suffix.sun', fallback: ' (sun)');
  static String profilesBoardTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.title', fallback: 'Profiles');
  static String profilesBoardEditCta(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.cta.edit', fallback: '✏ Edit');
  static String profilesBoardUpdated(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.updated', fallback: 'Profiles updated');
  static String profilesBoardDeleteTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.delete.title', fallback: 'Delete profile?');
  static String profilesBoardDeleteMessage(
    BuildContext context,
    String profileName,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.profiles.delete.message',
    params: <String, String>{'profileName': profileName},
    fallback: 'Delete "$profileName"? This cannot be undone.',
  );
  static String profilesBoardDeleteConfirm(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.delete.confirm', fallback: 'Delete');
  static String profilesBoardDeleted(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.deleted', fallback: 'Profile deleted');
  static String profilesBoardActiveBadge(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.badge.active', fallback: 'Active');
  static String profilesBoardTooltipEdit(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.tooltip.edit', fallback: 'Edit this profile');
  static String profilesBoardTooltipDelete(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.profiles.tooltip.delete',
        fallback: 'Delete this profile',
      );
  static String profilesBoardHomeFallback(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.homeFallback', fallback: 'Home');
  static String profilesBoardDestinationFallback(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.destinationFallback', fallback: 'Destination');

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
