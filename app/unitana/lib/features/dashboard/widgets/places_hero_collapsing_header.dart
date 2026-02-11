import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../models/dashboard_live_data.dart';
import '../models/dashboard_session_controller.dart';
import 'compact_reality_toggle.dart';
import 'pinned_mini_hero_readout.dart';
import 'places_hero_v2.dart';

/// Pinned, collapsing header that morphs PlacesHeroV2 into the compact
/// "mini hero" readout without threshold-based insertion.
///
/// Contract:
/// - No overlay + spacer strategy. The header itself collapses.
/// - The mini layer must fit inside [collapsedHeight] without clipping.
/// - Transition is continuous with scroll (opacity + small translate).
class PlacesHeroCollapsingHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final double horizontalPadding;
  final Place? home;
  final Place? destination;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;
  final Key? heroKey;

  const PlacesHeroCollapsingHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.horizontalPadding,
    required this.home,
    required this.destination,
    required this.session,
    required this.liveData,
    this.heroKey,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);

    // Expanded hero fades out slightly before the mini bar fully arrives.
    final heroOpacity = (1.0 - (t * 1.10)).clamp(0.0, 1.0);
    final heroTranslateY = lerpDouble(0, -26, t) ?? 0;

    // Mini bar tracks scroll closely (avoid feeling like a "state change").
    final miniOpacity = Curves.linear.transform(t);
    final miniTranslateY = lerpDouble(10, 0, t) ?? 0;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            height: maxExtent,
            child: RepaintBoundary(
              child: IgnorePointer(
                ignoring: t > 0.35,
                child: Opacity(
                  key: const ValueKey('dashboard_collapsing_header_hero_layer'),
                  opacity: heroOpacity,
                  child: Transform.translate(
                    offset: Offset(0, heroTranslateY),
                    child: KeyedSubtree(
                      key: const Key('places_hero_v2'),
                      child: PlacesHeroV2(
                        key: heroKey,
                        home: home,
                        destination: destination,
                        session: session,
                        liveData: liveData,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: IgnorePointer(
                // Keep interaction handoff aligned with the hero layer.
                // This avoids a dead zone where the mini is visible but untappable.
                ignoring: t < 0.35,
                child: Opacity(
                  key: const ValueKey('dashboard_collapsing_header_mini_layer'),
                  opacity: miniOpacity,
                  child: Transform.translate(
                    offset: Offset(0, miniTranslateY),
                    child: _PinnedBar(
                      height: collapsedHeight,
                      horizontalPadding: horizontalPadding,
                      home: home,
                      destination: destination,
                      session: session,
                      liveData: liveData,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PlacesHeroCollapsingHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        horizontalPadding != oldDelegate.horizontalPadding ||
        home != oldDelegate.home ||
        destination != oldDelegate.destination ||
        session != oldDelegate.session ||
        liveData != oldDelegate.liveData ||
        heroKey != oldDelegate.heroKey;
  }
}

class _PinnedBar extends StatelessWidget {
  final double height;
  final double horizontalPadding;
  final Place? home;
  final Place? destination;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;

  const _PinnedBar({
    required this.height,
    required this.horizontalPadding,
    required this.home,
    required this.destination,
    required this.session,
    required this.liveData,
  });

  String _flagEmoji(String? countryCode) {
    final code = (countryCode ?? '').trim().toUpperCase();
    if (code.length != 2) return '';
    final a = code.codeUnitAt(0);
    final b = code.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) return '';
    return String.fromCharCode(0x1F1E6 + (a - 65)) +
        String.fromCharCode(0x1F1E6 + (b - 65));
  }

  @override
  Widget build(BuildContext context) {
    if (home == null || destination == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[session, liveData]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final isHome = session.reality == DashboardReality.home;

        final homeLabel = '${_flagEmoji(home!.countryCode)} ${home!.cityName}'
            .trim();
        final destLabel =
            '${_flagEmoji(destination!.countryCode)} ${destination!.cityName}'
                .trim();

        return Material(
          elevation: 1,
          color: cs.surface.withAlpha(242),
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              8,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: CompactRealityToggle(
                      key: const ValueKey('dashboard_pinned_reality_toggle'),
                      isHome: isHome,
                      homeLabel: homeLabel,
                      destLabel: destLabel,
                      onPickHome: () =>
                          session.setReality(DashboardReality.home),
                      onPickDestination: () =>
                          session.setReality(DashboardReality.destination),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PinnedMiniHeroReadout(
                  key: const ValueKey('dashboard_pinned_mini_hero_readout'),
                  primary: isHome ? home! : destination!,
                  secondary: isHome ? destination! : home!,
                  liveData: liveData,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
