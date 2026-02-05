import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

/// Compact segmented toggle used in the dashboard (pinned mini hero) and
/// onboarding previews.
///
/// Contract:
/// - Fixed height to avoid layout jitter.
/// - Ellipsis for long labels.
/// - Stadium shapes for consistent tap targets.
class CompactRealityToggle extends StatelessWidget {
  final bool isHome;
  final String homeLabel;
  final String destLabel;
  final VoidCallback onPickHome;
  final VoidCallback onPickDestination;
  final Key homeSegmentKey;
  final Key destSegmentKey;

  const CompactRealityToggle({
    super.key,
    required this.isHome,
    required this.homeLabel,
    required this.destLabel,
    required this.onPickHome,
    required this.onPickDestination,
    this.homeSegmentKey = const ValueKey('dashboard_pinned_segment_home'),
    this.destSegmentKey = const ValueKey('dashboard_pinned_segment_dest'),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHighest.withAlpha(77);
    final border = cs.outlineVariant.withAlpha(179);

    Widget segment({
      required bool selected,
      required String text,
      required VoidCallback onTap,
      required Key key,
      Key? innerKey,
    }) {
      return Expanded(
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            key: innerKey,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer.withAlpha(140) : bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface.withAlpha(230),
                          ) ??
                          const TextStyle())
                      .merge(GoogleFonts.robotoSlab()),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          segment(
            selected: isHome,
            text: homeLabel,
            onTap: onPickHome,
            key: homeSegmentKey,
          ),
          const SizedBox(width: 6),
          segment(
            selected: !isHome,
            text: destLabel,
            onTap: onPickDestination,
            key: destSegmentKey,
          ),
        ],
      ),
    );
  }
}
