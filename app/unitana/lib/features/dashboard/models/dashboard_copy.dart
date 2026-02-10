import 'package:flutter/material.dart';

import '../../../l10n/city_picker_copy.dart';
import '../../../l10n/dashboard_localizations.dart';
import 'dashboard_live_data.dart';
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
        fallback: 'Tap a row to focus. Tap any value cell to copy.',
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
    final fallback = 'From Time Zone';
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String timeToZoneTitle(
    BuildContext context, {
    required bool isJetLagTool,
  }) {
    final key = isJetLagTool
        ? 'dashboard.time.toZone.jetLag'
        : 'dashboard.time.toZone.standard';
    final fallback = 'To Time Zone';
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
  static String timeConverterInputHint(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.time.converter.inputHint',
        fallback: '2026-02-06 18:30',
      );

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
  static String jetLagSchedulePickerHelp(
    BuildContext context, {
    required bool bedtime,
  }) => DashboardLocalizations.of(context).text(
    bedtime
        ? 'dashboard.jetLag.schedule.help.bedtime'
        : 'dashboard.jetLag.schedule.help.wake',
    fallback: bedtime ? 'Typical bedtime' : 'Typical wake time',
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
  static String dashboardSetCityCta(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.setCityCta', fallback: 'Set city');
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
  static String settingsTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.title', fallback: 'Settings');
  static String settingsOptionAbout(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.option.about', fallback: 'About');
  static String settingsOptionLicenses(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.option.licenses', fallback: 'Licenses');
  static String settingsLanguageTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.language.title', fallback: 'Language');
  static String settingsThemeTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.theme.title', fallback: 'Theme');
  static String settingsThemeSystem(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.theme.option.system', fallback: 'System');
  static String settingsThemeDark(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.theme.option.dark', fallback: 'Dark');
  static String settingsThemeLight(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.theme.option.light', fallback: 'Light');
  static String settingsThemeUpdated(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.theme.updated', fallback: 'Theme updated');
  static String settingsLanguageSystem(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.language.option.system',
        fallback: 'System default',
      );
  static String settingsLanguageEnglish(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.language.option.en', fallback: 'English');
  static String settingsLanguageSpanish(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.language.option.es', fallback: 'Español');
  static String settingsLanguageFrench(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.language.option.fr', fallback: 'Français');
  static String settingsLanguagePortuguesePortugal(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.language.option.ptPT',
        fallback: 'Português (Portugal)',
      );
  static String settingsLanguageUpdated(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.language.updated',
        fallback: 'Language updated',
      );
  static String settingsProfileSuggestTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.profileSuggest.title',
        fallback: 'Auto-suggest profile by location',
      );
  static String settingsProfileSuggestEnabled(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.profileSuggest.enabled', fallback: 'On');
  static String settingsProfileSuggestDisabled(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.profileSuggest.disabled', fallback: 'Off');
  static String settingsProfileSuggestUpdated(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.profileSuggest.updated',
        fallback: 'Profile suggestion setting updated',
      );
  static String settingsLofiAudioTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.lofi.title',
        fallback: 'Lo-fi background audio',
      );
  static String settingsLofiAudioOn(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.lofi.on', fallback: 'On');
  static String settingsLofiAudioOff(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.lofi.off', fallback: 'Off');
  static String settingsLofiAudioVolume(
    BuildContext context, {
    required int percent,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.settings.lofi.volume',
    params: <String, String>{'percent': '$percent'},
    fallback: 'Volume $percent%',
  );
  static String settingsLofiAudioUpdated(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.lofi.updated',
        fallback: 'Lo-fi audio setting updated',
      );
  static String settingsProfileSuggestReasonUnavailable(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.profileSuggest.reason.unavailable',
        fallback: 'Location unavailable; profile suggestions are idle.',
      );
  static String settingsProfileSuggestSuggested(
    BuildContext context, {
    required String profileName,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.settings.profileSuggest.suggested',
    params: <String, String>{'profileName': profileName},
    fallback: 'Suggested profile: $profileName',
  );
  static String settingsAboutTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.about.title', fallback: 'About Unitana');
  static String settingsAboutTagline(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.about.tagline',
        fallback: 'Travel-first decoder ring; dual reality side-by-side',
      );
  static String settingsAboutBody(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.settings.about.body',
    fallback:
        'Unitana helps compare home and destination contexts with practical tools for time, weather, and conversions.',
  );
  static String settingsAboutLegalese(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.about.legalese',
        fallback: 'Copyright 2026 Unitana contributors',
      );
  static String settingsLicensesTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.licenses.title',
        fallback: 'Open-source licenses',
      );
  static String settingsLicensesReadableTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.licenses.readable.title',
        fallback: 'Readable license index',
      );
  static String settingsLicensesReadableBody(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.settings.licenses.readable.body',
    fallback:
        'Browse dependencies by package. Expand a package to view full license text, or open the raw legal page.',
  );
  static String settingsLicensesPackages(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.licenses.packages', fallback: 'Packages');
  static String settingsLicensesEntries(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.settings.licenses.entries', fallback: 'entries');
  static String settingsLicensesOpenRaw(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.licenses.openRaw',
        fallback: 'Open raw legal text',
      );
  static String settingsLicensesViewDetails(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.settings.licenses.viewDetails',
        fallback: 'View full text',
      );
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
  static String devtoolsWeatherBackendLabel(
    BuildContext context, {
    required String backendKey,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.backend.$backendKey',
    fallback: switch (backendKey) {
      'mock' => 'Demo (no network)',
      'openMeteo' => 'Live: Open-Meteo',
      'weatherApi' => 'Live: WeatherAPI',
      _ => backendKey,
    },
  );
  static String devtoolsWeatherBackendShortLabel(
    BuildContext context, {
    required String backendKey,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.backendShort.$backendKey',
    fallback: switch (backendKey) {
      'mock' => 'Demo',
      'openMeteo' => 'Open-Meteo',
      'weatherApi' => 'WeatherAPI',
      _ => backendKey,
    },
  );
  static String devtoolsWeatherConditionLabel(
    BuildContext context, {
    required String conditionKey,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.devtools.weather.condition.$conditionKey',
    fallback: switch (conditionKey) {
      'clear' => 'Clear',
      'partlyCloudy' => 'Partly Cloudy',
      'cloudy' => 'Cloudy',
      'overcast' => 'Overcast',
      'drizzle' => 'Drizzle',
      'rain' => 'Rain',
      'thunderstorm' => 'Thunderstorm',
      'snow' => 'Snow',
      'sleet' => 'Sleet',
      'hail' => 'Hail',
      'fog' => 'Fog',
      'mist' => 'Mist',
      'haze' => 'Haze',
      'smoke' => 'Smoke',
      'dust' => 'Dust',
      'sand' => 'Sand',
      'ash' => 'Ash',
      'squall' => 'Squall',
      'tornado' => 'Tornado',
      'windy' => 'Windy',
      _ => conditionKey,
    },
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
      ).text('dashboard.profiles.homeFallback', fallback: 'City not set');
  static String profilesBoardDestinationFallback(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.profiles.destinationFallback',
        fallback: 'City not set',
      );
  static String profilesDefaultName(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.profiles.defaultName', fallback: 'New Profile');

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
  static String tipAmountHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tip.inputHint.amount', fallback: '100.00');

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

  static String taxAmountHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tax.inputHint.amount', fallback: '100.00');

  static String unitPriceCompareInvalid(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.unitPrice.compareInvalid',
        fallback: 'Comparison needs valid values in the same unit family.',
      );
  static String unitPricePriceHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.unitPrice.inputHint.price', fallback: '4.99');
  static String unitPriceQuantityHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.unitPrice.inputHint.quantity', fallback: '500');
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
  static String unitPriceCoach(
    BuildContext context, {
    String? primaryCurrency,
    String? secondaryCurrency,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.unitPrice.coach',
    fallback:
        'How to use: enter shelf price and package size for Product A. Turn on comparison to add Product B in the same unit family (mass or volume).',
  );

  static String bakingInputCoach(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.baking.input.coach',
    fallback:
        'Supports decimals and fractions (for example 1/2 or 1 1/2). Use unit pills for tsp, tbsp, cup, mL, and L.',
  );
  static String toolPickerTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.title', fallback: 'Choose a tool');
  static String toolPickerSearchHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.searchHint', fallback: 'Search tools');
  static String toolPickerCloseTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.tooltip.close', fallback: 'Close tools');
  static String toolPickerMostRecent(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.mostRecent', fallback: 'Most recent');
  static String toolPickerDisabledBadge(
    BuildContext context, {
    required bool isDeferred,
  }) => DashboardLocalizations.of(context).text(
    isDeferred
        ? 'dashboard.toolPicker.badge.deferred'
        : 'dashboard.toolPicker.badge.soon',
    fallback: isDeferred ? 'Deferred' : 'Soon',
  );
  static String toolPickerActionReplace(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.action.replace', fallback: 'Replace tile');
  static String toolPickerActionRemove(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.action.remove', fallback: 'Remove tile');
  static String toolPickerActionRemoveConfirmTitle(
    BuildContext context,
    String label,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.toolPicker.action.removeTitle',
    params: <String, String>{'label': label},
    fallback: 'Remove $label?',
  );
  static String toolPickerActionRemoveConfirmMessage(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.toolPicker.action.removeMessage',
        fallback: 'This tile will be removed from your dashboard.',
      );
  static String toolPickerActionRemoveConfirmCta(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.action.removeCta', fallback: 'Remove');
  static String convertCta(BuildContext context) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tool.cta.convert', fallback: 'Convert');
  static String toolInputHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.tool.input.hint', fallback: 'Enter Value');
  static String paceInputHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.pace.input.hint', fallback: '5:30');
  static String paceInputCoach(
    BuildContext context, {
    required String fromUnit,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.pace.input.coach',
    params: <String, String>{'fromUnit': fromUnit},
    fallback:
        'Enter minutes:seconds in $fromUnit (example: 5:30). We will convert that pace directly.',
  );
  static String unitPickerTitle(
    BuildContext context, {
    required bool isCurrencyTool,
    required bool isFrom,
  }) {
    final key = isCurrencyTool
        ? (isFrom
              ? 'dashboard.tool.unitPicker.fromCurrency'
              : 'dashboard.tool.unitPicker.toCurrency')
        : (isFrom
              ? 'dashboard.tool.unitPicker.fromUnit'
              : 'dashboard.tool.unitPicker.toUnit');
    final fallback = isCurrencyTool
        ? (isFrom ? 'From Currency' : 'To Currency')
        : (isFrom ? 'From Unit' : 'To Unit');
    return DashboardLocalizations.of(context).text(key, fallback: fallback);
  }

  static String unitPickerCloseTooltip(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.tool.unitPicker.tooltip.close',
        fallback: 'Close picker',
      );
  static String timePickerModeCities(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.picker.mode.cities', fallback: 'Cities');
  static String timePickerModeAdvancedZones(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.time.picker.mode.advancedZones',
        fallback: 'Advanced: Time Zones',
      );
  static String timePickerSearchHint(
    BuildContext context, {
    required bool advancedMode,
  }) => DashboardLocalizations.of(context).text(
    advancedMode
        ? 'dashboard.time.picker.searchHint.advanced'
        : 'dashboard.time.picker.searchHint.city',
    fallback: advancedMode
        ? 'Search timezone ID or city'
        : 'Search city or country',
  );
  static String timePickerExpandedSearchHint(BuildContext context) =>
      CityPickerCopy.searchHint(context, mode: CityPickerMode.cityAndTimezone);
  static String timePickerSearching(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.time.picker.searching', fallback: 'Searching…');
  static String timePickerQuickChipDetail(BuildContext context, String code) =>
      DashboardLocalizations.of(context).text(
        'dashboard.time.picker.quick.$code',
        fallback: switch (code) {
          'EST' => 'New York',
          'CST' => 'Chicago',
          'PST' => 'Los Angeles',
          'UTC' => 'Zero offset',
          _ => code,
        },
      );
  static String timePickerPrimaryHeader(
    BuildContext context, {
    required bool hasQuery,
  }) => hasQuery
      ? CityPickerCopy.bestMatchesHeader(context)
      : CityPickerCopy.topHeader(context);
  static String timePickerNoMatchesHint(BuildContext context) =>
      CityPickerCopy.emptyHint(context, mode: CityPickerMode.cityAndTimezone);
  static String timePickerDirectZonesHeader(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.time.picker.header.directZones',
        fallback: 'Direct Time Zones',
      );
  static String timeConverterInputError(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.time.converter.invalidInput',
        fallback: 'Enter date/time as YYYY-MM-DD HH:MM',
      );

  static String weatherCityNotSet(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.cityNotSet', fallback: 'City not set');
  static String weatherHeaderSunrise(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.sunrise', fallback: '☀️ Sunrise');
  static String weatherHeaderSunset(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.sunset', fallback: '🌙 Sunset');
  static String weatherHeaderWind(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.wind', fallback: '🌬️ Wind');
  static String weatherHeaderGust(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.gust', fallback: '💨 Gust');
  static String weatherHeaderAqi(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.aqi', fallback: '🌫️ AQI (US)');
  static String weatherHeaderPollen(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.header.pollen', fallback: '🌼 Pollen (0-5)');
  static String weatherBannerHighLow(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.banner.highLow', fallback: 'High • Low');
  static String weatherEmergencyLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.emergency.label', fallback: 'Weather alert');
  static String weatherEmergencyReason(
    BuildContext context, {
    required String reasonKey,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.weather.emergency.reason.$reasonKey',
    fallback: switch (reasonKey) {
      'tornado' => 'Tornado risk',
      'thunder_snow' => 'Thundersnow risk',
      'thunderstorm' => 'Thunderstorm risk',
      'blizzard' => 'Blizzard conditions',
      'squall' => 'Squall conditions',
      'ice' => 'Icy conditions',
      'high_wind' => 'Strong winds',
      'wildfire_smoke' => 'Wildfire smoke',
      'ashfall' => 'Ash in air',
      'air_hazardous' => 'Hazardous air quality',
      'air_unhealthy' => 'Unhealthy air quality',
      'air_sensitive' => 'Air quality concern',
      'pollen_very_high' => 'Very high pollen',
      'provider_warning' => 'Provider warning',
      'provider_watch' => 'Provider watch',
      'provider_advisory' => 'Provider advisory',
      _ => 'Monitor conditions',
    },
  );
  static String weatherEmergencyShortLabel(
    BuildContext context, {
    required WeatherEmergencySeverity severity,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.weather.emergency.short.${severity.name}',
    fallback: switch (severity) {
      WeatherEmergencySeverity.none => 'Normal',
      WeatherEmergencySeverity.advisory => 'Advisory',
      WeatherEmergencySeverity.watch => 'Watch',
      WeatherEmergencySeverity.warning => 'Warning',
      WeatherEmergencySeverity.emergency => 'Emergency',
    },
  );
  static String weatherForecastModeLabel(
    BuildContext context, {
    required bool daily,
  }) => DashboardLocalizations.of(context).text(
    daily
        ? 'dashboard.weather.forecast.mode.daily'
        : 'dashboard.weather.forecast.mode.hourly',
    fallback: daily ? '7-day' : 'Hourly',
  );
  static String weatherForecastUnitsLegend(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.weather.forecast.unitsLegend', fallback: '°C | °F');
  static String weatherForecastSwapTooltip(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.weather.forecast.swapTooltip',
        fallback: 'Tap to swap hourly / 7-day',
      );
  static String weatherForecastUnavailable(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.weather.forecast.unavailable',
        fallback: 'Forecast unavailable',
      );
  static String weatherAqiBand(BuildContext context, String bandKey) =>
      DashboardLocalizations.of(context).text(
        'dashboard.weather.aqi.$bandKey',
        fallback: switch (bandKey) {
          'good' => 'Good',
          'moderate' => 'Moderate',
          'unhealthySensitive' => 'Unhealthy (Sensitive)',
          'unhealthy' => 'Unhealthy',
          'veryUnhealthy' => 'Very Unhealthy',
          'hazardous' => 'Hazardous',
          _ => bandKey,
        },
      );
  static String weatherPollenBand(BuildContext context, String bandKey) =>
      DashboardLocalizations.of(context).text(
        'dashboard.weather.pollen.$bandKey',
        fallback: switch (bandKey) {
          'low' => 'Low',
          'moderate' => 'Moderate',
          'high' => 'High',
          'veryHigh' => 'Very High',
          _ => bandKey,
        },
      );
  static String weatherConditionByScene(
    BuildContext context,
    SceneKey? sceneKey,
  ) {
    final keySuffix = switch (sceneKey) {
      SceneKey.clear => 'clear',
      SceneKey.partlyCloudy => 'partlyCloudy',
      SceneKey.cloudy => 'cloudy',
      SceneKey.overcast => 'overcast',
      SceneKey.mist => 'mist',
      SceneKey.fog => 'fog',
      SceneKey.drizzle => 'drizzle',
      SceneKey.freezingDrizzle => 'freezingDrizzle',
      SceneKey.rainLight => 'rainLight',
      SceneKey.rainModerate => 'rainModerate',
      SceneKey.rainHeavy => 'rainHeavy',
      SceneKey.freezingRain => 'freezingRain',
      SceneKey.sleet => 'sleet',
      SceneKey.snowLight => 'snowLight',
      SceneKey.snowModerate => 'snowModerate',
      SceneKey.snowHeavy => 'snowHeavy',
      SceneKey.blowingSnow => 'blowingSnow',
      SceneKey.blizzard => 'blizzard',
      SceneKey.icePellets => 'icePellets',
      SceneKey.thunderRain => 'thunderRain',
      SceneKey.thunderSnow => 'thunderSnow',
      SceneKey.hazeDust => 'hazeDust',
      SceneKey.smokeWildfire => 'smokeWildfire',
      SceneKey.ashfall => 'ashfall',
      SceneKey.windy => 'windy',
      SceneKey.tornado => 'tornado',
      SceneKey.squall => 'squall',
      null => 'weather',
    };
    final fallback = switch (sceneKey) {
      SceneKey.clear => 'Clear',
      SceneKey.partlyCloudy => 'Partly cloudy',
      SceneKey.cloudy => 'Cloudy',
      SceneKey.overcast => 'Overcast',
      SceneKey.mist => 'Mist',
      SceneKey.fog => 'Fog',
      SceneKey.drizzle => 'Drizzle',
      SceneKey.freezingDrizzle => 'Freezing drizzle',
      SceneKey.rainLight => 'Light rain',
      SceneKey.rainModerate => 'Rain',
      SceneKey.rainHeavy => 'Heavy rain',
      SceneKey.freezingRain => 'Freezing rain',
      SceneKey.sleet => 'Sleet',
      SceneKey.snowLight => 'Light snow',
      SceneKey.snowModerate => 'Snow',
      SceneKey.snowHeavy => 'Heavy snow',
      SceneKey.blowingSnow => 'Blowing snow',
      SceneKey.blizzard => 'Blizzard',
      SceneKey.icePellets => 'Ice pellets',
      SceneKey.thunderRain => 'Thunderstorm',
      SceneKey.thunderSnow => 'Thunder snow',
      SceneKey.hazeDust => 'Haze',
      SceneKey.smokeWildfire => 'Smoke',
      SceneKey.ashfall => 'Ash',
      SceneKey.windy => 'Windy',
      SceneKey.tornado => 'Tornado',
      SceneKey.squall => 'Squall',
      null => 'Weather',
    };
    return DashboardLocalizations.of(
      context,
    ).text('dashboard.weather.condition.$keySuffix', fallback: fallback);
  }

  static String weatherConditionLabel(
    BuildContext context, {
    required SceneKey? sceneKey,
    required String? rawText,
  }) {
    final raw = (rawText ?? '').trim();
    if (raw.isEmpty || raw == '—') {
      return weatherConditionByScene(context, sceneKey);
    }
    final normalized = raw.toLowerCase();
    final mapped = _conditionRawToScene[normalized];
    if (mapped != null) {
      return weatherConditionByScene(context, mapped);
    }
    return raw;
  }

  static String heroEnvLabel(BuildContext context, {required bool isAqi}) =>
      DashboardLocalizations.of(context).text(
        isAqi
            ? 'dashboard.hero.env.label.aqi'
            : 'dashboard.hero.env.label.pollen',
        fallback: isAqi ? 'AQI' : 'Pollen',
      );
  static String heroEnvBandShort(
    BuildContext context, {
    required bool isAqi,
    required String bandKey,
  }) => DashboardLocalizations.of(context).text(
    isAqi
        ? 'dashboard.hero.env.bandShort.aqi.$bandKey'
        : 'dashboard.hero.env.bandShort.pollen.$bandKey',
    fallback: switch (bandKey) {
      'good' => 'Good',
      'moderate' => 'Mod',
      'usg' => 'USG',
      'unhealthy' => 'Unh',
      'veryUnhealthy' => 'VUnh',
      'hazardous' => 'Haz',
      'low' => 'Low',
      'medium' => 'Med',
      'high' => 'High',
      'veryHigh' => 'VHigh',
      _ => bandKey,
    },
  );
  static String heroEnvIndexSuffix(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.hero.env.indexSuffix', fallback: ' idx');
  static String heroEnvSemantics(
    BuildContext context, {
    required bool isAqi,
  }) => DashboardLocalizations.of(context).text(
    isAqi
        ? 'dashboard.hero.env.semantics.aqi'
        : 'dashboard.hero.env.semantics.pollen',
    fallback: isAqi
        ? 'Air quality index for the selected city. Tap to show pollen index.'
        : 'Pollen index for the selected city. Tap to show air quality index.',
  );
  static String heroDetailsSemantics(
    BuildContext context, {
    required bool isWind,
  }) => DashboardLocalizations.of(context).text(
    isWind
        ? 'dashboard.hero.details.semantics.wind'
        : 'dashboard.hero.details.semantics.sun',
    fallback: isWind
        ? 'Wind details. Tap to show sunrise and sunset.'
        : 'Sunrise and sunset details. Tap to show wind.',
  );
  static String heroDetailsTitle(
    BuildContext context, {
    required bool isWind,
  }) => DashboardLocalizations.of(context).text(
    isWind
        ? 'dashboard.hero.details.title.wind'
        : 'dashboard.hero.details.title.sun',
    fallback: isWind ? 'Wind • Gust' : 'Sunrise • Sunset',
  );
  static String heroCurrencyRatePrefix(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.hero.currency.ratePrefix', fallback: 'Rate:');
  static String heroCurrencyRateSameCurrency(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.hero.currency.rate.sameCurrency',
        fallback: 'Rate: same currency',
      );
  static String heroCurrencyRateUnavailable(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.hero.currency.rate.unavailable', fallback: 'Rate: —');
  static String heroCurrencyRatePair(
    BuildContext context, {
    required String leftRate,
    required String rightRate,
  }) => DashboardLocalizations.of(context).text(
    'dashboard.hero.currency.rate.pair',
    params: <String, String>{'leftRate': leftRate, 'rightRate': rightRate},
    fallback: 'Rate: $leftRate = $rightRate',
  );

  static const Map<String, SceneKey> _conditionRawToScene = <String, SceneKey>{
    'clear': SceneKey.clear,
    'mostly clear': SceneKey.partlyCloudy,
    'partly cloudy': SceneKey.partlyCloudy,
    'cloudy': SceneKey.cloudy,
    'overcast': SceneKey.overcast,
    'mist': SceneKey.mist,
    'fog': SceneKey.fog,
    'drizzle': SceneKey.drizzle,
    'freezing drizzle': SceneKey.freezingDrizzle,
    'light rain': SceneKey.rainLight,
    'rain': SceneKey.rainModerate,
    'heavy rain': SceneKey.rainHeavy,
    'freezing rain': SceneKey.freezingRain,
    'rain showers': SceneKey.rainModerate,
    'sleet': SceneKey.sleet,
    'light snow': SceneKey.snowLight,
    'snow': SceneKey.snowModerate,
    'heavy snow': SceneKey.snowHeavy,
    'snow grains': SceneKey.snowLight,
    'snow showers': SceneKey.snowModerate,
    'blowing snow': SceneKey.blowingSnow,
    'blizzard': SceneKey.blizzard,
    'ice pellets': SceneKey.icePellets,
    'thunderstorm': SceneKey.thunderRain,
    'thunder snow': SceneKey.thunderSnow,
    'haze': SceneKey.hazeDust,
    'smoke': SceneKey.smokeWildfire,
    'ash': SceneKey.ashfall,
    'windy': SceneKey.windy,
    'tornado': SceneKey.tornado,
    'squall': SceneKey.squall,
    'weather': SceneKey.overcast,
  };
  static String toolPickerNoMatchingTools(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.toolPicker.noMatchingTools',
        fallback: 'No matching tools.',
      );
  static String toolPickerNoToolsYet(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.noToolsYet', fallback: 'No tools yet.');
  static String toolPickerResultsHeader(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.toolPicker.resultsHeader', fallback: 'Results');
  static String toolPickerMoreCount(BuildContext context, int remaining) =>
      DashboardLocalizations.of(context).text(
        'dashboard.toolPicker.moreCount',
        params: <String, String>{'count': '$remaining'},
        fallback: '+$remaining more',
      );
  static String toolDisplayName(
    BuildContext context, {
    required String toolId,
    required String fallback,
  }) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tools.$toolId.title', fallback: fallback);
  static String toolWidgetDisplayName(
    BuildContext context, {
    required String toolId,
    required String fallback,
  }) => DashboardLocalizations.of(
    context,
  ).text('dashboard.tools.$toolId.widgetTitle', fallback: fallback);
  static String lensName(
    BuildContext context, {
    required String lensId,
    required String fallback,
  }) => DashboardLocalizations.of(
    context,
  ).text('dashboard.lens.$lensId.name', fallback: fallback);
  static String lensDescriptor(
    BuildContext context, {
    required String lensId,
    required String fallback,
  }) => DashboardLocalizations.of(
    context,
  ).text('dashboard.lens.$lensId.description', fallback: fallback);
  static String firstRunCancelTooltip(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.tooltip.cancel', fallback: 'Cancel setup');
  static String firstRunWelcomeTitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.welcome.title',
        fallback: 'Welcome to Unitana',
      );
  static String firstRunWelcomeTagline(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.firstRun.welcome.tagline',
    fallback:
        'A dual-reality dashboard for the stuff\nyour brain keeps converting anyway.',
  );
  static String firstRunPlacesTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.places.title', fallback: 'Pick Your Places');
  static String firstRunPlacesSubtitle(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.places.subtitle',
        fallback: 'Your here and your there, side by side.',
      );
  static String firstRunPickBothPreview(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.places.pickBoth',
        fallback: 'Pick both places to preview the mini hero.',
      );
  static String firstRunChooseHome(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.cta.chooseHome', fallback: 'Choose Home city');
  static String firstRunChooseDestination(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.cta.chooseDestination',
        fallback: 'Choose Destination city',
      );
  static String firstRunUnitMetric(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.unit.metric', fallback: 'Metric');
  static String firstRunUnitImperial(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.unit.imperial', fallback: 'Imperial');
  static String firstRunClock12h(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.clock.12h', fallback: '12-Hour');
  static String firstRunClock24h(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.clock.24h', fallback: '24-Hour');
  static String firstRunConfirmTitle(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.confirm.title', fallback: 'Name and Confirm');
  static String firstRunConfirmSubtitle(
    BuildContext context,
  ) => DashboardLocalizations.of(context).text(
    'dashboard.firstRun.confirm.subtitle',
    fallback:
        'This name shows in the header and in your profile list. Keep it short.',
  );
  static String firstRunProfileNameLabel(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.profileName.label', fallback: 'Profile Name');
  static String firstRunProfileNameHint(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.profileName.hint', fallback: 'Lisbon');
  static String firstRunPickCitiesHint(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.confirm.pickCities',
        fallback: 'Go back and pick Home + Destination to preview the hero.',
      );
  static String firstRunSaveChanges(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.firstRun.cta.saveChanges', fallback: 'Save Changes');
  static String firstRunCreateProfile(BuildContext context) =>
      DashboardLocalizations.of(context).text(
        'dashboard.firstRun.cta.createProfile',
        fallback: 'Create Profile',
      );
  static String ratesStaleShort(BuildContext context) =>
      DashboardLocalizations.of(
        context,
      ).text('dashboard.dashboard.ratesStaleShort', fallback: 'Rates stale');

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
