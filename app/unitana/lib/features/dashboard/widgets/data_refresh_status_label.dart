import 'dart:async';

import 'package:flutter/material.dart';
import '../../../theme/dracula_palette.dart';

import '../models/dashboard_live_data.dart';

/// Small, provider-agnostic "last refresh" label for live data.
///
/// Display-only: never triggers refresh. It recalculates the human-readable age
/// every minute so the UI stays truthful while the user is idle.
class DataRefreshStatusLabel extends StatefulWidget {
  final DashboardLiveDataController liveData;

  /// If true, renders nothing when live weather is not enabled.
  final bool hideWhenUnavailable;

  /// Age after which we describe the data as "stale".
  final Duration staleAfter;

  /// Compact sizing (used by the hero rail).
  final bool compact;

  /// If true, wraps the text in a subtle pill background.
  final bool showBackground;

  const DataRefreshStatusLabel({
    super.key,
    required this.liveData,
    this.hideWhenUnavailable = true,
    this.staleAfter = const Duration(minutes: 10),
    this.compact = false,
    this.showBackground = false,
  });

  @override
  State<DataRefreshStatusLabel> createState() => _DataRefreshStatusLabelState();
}

class _DataRefreshStatusLabelState extends State<DataRefreshStatusLabel> {
  Timer? _ticker;

  bool get _isTest {
    if (bool.fromEnvironment('FLUTTER_TEST')) return true;
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  }

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() {
          // Recompute age text.
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? _buildLabel(DashboardLiveDataController liveData) {
    final isLive =
        liveData.weatherNetworkEnabled &&
        liveData.weatherBackend != WeatherBackend.mock;
    if (!isLive && widget.hideWhenUnavailable) return null;

    if (liveData.isRefreshing) return 'Updating…';

    final last = liveData.lastRefreshedAt;
    if (last == null) return 'Not updated';

    final age = DateTime.now().difference(last);
    final ageText = _ageText(age);

    if (age > widget.staleAfter) {
      return 'Stale ($ageText)';
    }

    return 'Updated $ageText';
  }

  static String _ageText(Duration age) {
    final secs = age.inSeconds;
    if (secs < 60) return 'just now';

    final mins = age.inMinutes;
    if (mins < 60) return '${mins}m ago';

    final hours = age.inHours;
    if (hours < 24) return '${hours}h ago';

    final days = age.inDays;
    return '${days}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.liveData,
      builder: (context, _) {
        final text = _buildLabel(widget.liveData);
        if (text == null) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final bool isStale = text.startsWith('Stale');
        final Color labelColor = isStale
            ? DraculaPalette.orange.withAlpha(235)
            : DraculaPalette.purple.withAlpha(220);

        final baseStyle =
            (widget.compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.bodySmall)
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  // More intrigue than a pill, while staying readable.
                  color: labelColor,
                );

        final child = Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: baseStyle,
        );

        if (!widget.showBackground) return child;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 10,
            vertical: widget.compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(120),
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
            border: Border.all(color: cs.outlineVariant.withAlpha(160)),
          ),
          child: child,
        );
      },
    );
  }
}
