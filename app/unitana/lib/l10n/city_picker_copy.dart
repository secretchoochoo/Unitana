import 'package:flutter/material.dart';

import 'dashboard_localizations.dart';

enum CityPickerMode { cityOnly, cityAndTimezone }

class CityPickerCopy {
  const CityPickerCopy._();

  static String title(BuildContext context, {required CityPickerMode mode}) {
    return DashboardLocalizations.of(
      context,
    ).text('dashboard.cityPicker.title', fallback: 'Choose a city');
  }

  static String closeTooltip(BuildContext context) {
    return DashboardLocalizations.of(
      context,
    ).text('dashboard.cityPicker.tooltip.close', fallback: 'Close');
  }

  static String searchHint(
    BuildContext context, {
    required CityPickerMode mode,
  }) {
    return DashboardLocalizations.of(context).text(
      mode == CityPickerMode.cityOnly
          ? 'dashboard.cityPicker.searchHint.cityOnly'
          : 'dashboard.cityPicker.searchHint.cityAndTimezone',
      fallback: mode == CityPickerMode.cityOnly
          ? 'Search city or country'
          : 'Search city, country, timezone, or EST',
    );
  }

  static String topHeader(BuildContext context) {
    return DashboardLocalizations.of(
      context,
    ).text('dashboard.cityPicker.header.topCities', fallback: 'Top Cities');
  }

  static String bestMatchesHeader(BuildContext context) {
    return DashboardLocalizations.of(
      context,
    ).text('dashboard.cityPicker.header.bestMatches', fallback: 'Best Matches');
  }

  static String emptyHint(
    BuildContext context, {
    required CityPickerMode mode,
  }) {
    return DashboardLocalizations.of(context).text(
      mode == CityPickerMode.cityOnly
          ? 'dashboard.cityPicker.empty.cityOnly'
          : 'dashboard.cityPicker.empty.cityAndTimezone',
      fallback: mode == CityPickerMode.cityOnly
          ? 'No matches yet. Try city or country.'
          : 'No matches yet. Try city, country, timezone, or EST.',
    );
  }
}
