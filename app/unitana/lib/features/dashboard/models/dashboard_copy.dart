import 'jet_lag_planner.dart';

class DashboardCopy {
  const DashboardCopy._();

  static const String updating = 'Updating…';
  static const String notUpdated = 'Not updated';

  static String updated(String age) => 'Updated $age';
  static String stale(String age) => 'Stale ($age)';

  static String weatherStaleSuffix({required bool isStale}) =>
      isStale ? ' (stale)' : '';

  static String currencyStaleRetryNow(String age) =>
      'Rates are stale (last error $age). You can retry now.';

  static String currencyStaleRetrySoon(String age) =>
      'Rates are stale (last error $age). Retrying in a moment.';

  static const String currencyUsingCachedRates =
      'Using cached rates. They may be stale.';
  static const String retryRatesCta = 'Retry rates';

  static String factsTitle({required bool isJetLagTool}) =>
      isJetLagTool ? 'Travel Facts' : 'Current Clocks';

  static const String jetLagPlanTitle = 'Jet Lag Plan';
  static const String quickTipsTitle = 'Quick Tips';
  static const String callWindowsTitle = 'Call Windows';
  static const String showCallWindowsCta = 'Show call windows';
  static const String overlapIntro = 'Quick check before scheduling calls:';

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
