import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme_extensions.dart';

class UnitanaTile extends StatelessWidget {
  final String title;
  final String primary;
  final String secondary;
  final String footer;
  final String? hint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? leadingIcon;
  final Gradient? backgroundGradient;

  /// Optional accent override used for icon + footer cue coloring.
  ///
  /// When null, the tile falls back to the app's default accent behavior.
  final Color? accentColor;

  const UnitanaTile({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.footer,
    this.hint,
    this.onTap,
    this.onLongPress,
    this.leadingIcon,
    this.backgroundGradient,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<UnitanaLayoutTokens>() ??
        UnitanaLayoutTokens.softGeometry;
    final brand =
        Theme.of(context).extension<UnitanaBrandTokens>() ??
        UnitanaBrandTokens.dark;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final iconAccent = accentColor ?? scheme.primary;
    final dotAccent = accentColor ?? brand.accent;

    String oneLine(String value) => value
        .replaceAll(RegExp(r'[\n\r]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final safeTitle = oneLine(title);
    final safePrimary = oneLine(primary);
    final safeSecondary = oneLine(secondary);
    final safeFooter = oneLine(footer);
    final safeHint = hint == null ? null : oneLine(hint!);

    final borderRadius = BorderRadius.circular(tokens.cornerRadiusM);

    final card = Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        color: backgroundGradient == null ? scheme.surface : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: scheme.outlineVariant,
          width: tokens.strokeHairline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              (constraints.maxHeight.isFinite &&
                  constraints.maxHeight <= 120) ||
              (constraints.maxWidth.isFinite && constraints.maxWidth <= 160);

          final isMicro =
              (constraints.maxHeight.isFinite && constraints.maxHeight <= 92) ||
              (constraints.maxWidth.isFinite && constraints.maxWidth <= 140);

          final pad = isMicro
              ? tokens.gutterXS * 0.45
              : (isCompact ? tokens.gutterXS * 0.6 : tokens.gutterXS);
          final vGap = isMicro
              ? tokens.gutterXS * 0.15
              : (isCompact ? tokens.gutterXS * 0.35 : tokens.gutterXS * 0.6);
          final hGap = isMicro
              ? tokens.gutterXS * 0.25
              : (isCompact ? tokens.gutterXS * 0.5 : tokens.gutterXS * 0.75);
          final midGap = isMicro
              ? tokens.gutterXS * 0.1
              : (isCompact ? tokens.gutterXS * 0.25 : tokens.gutterXS * 0.4);

          final iconBox = isMicro ? 24.0 : (isCompact ? 28.0 : 32.0);
          final iconRadius = isMicro ? 8.0 : (isCompact ? 9.0 : 12.0);
          final iconSize = isMicro ? 13.0 : (isCompact ? 15.0 : 18.0);

          final primarySize = isMicro ? 16.0 : (isCompact ? 18.0 : 28.0);

          final hasSecondary = safeSecondary.trim().isNotEmpty && !isMicro;
          final hasFooter = safeFooter.trim().isNotEmpty;

          Widget buildPrimary() => SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                safePrimary,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: text.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: primarySize,
                  height: 1.0,
                ),
              ),
            ),
          );

          Widget buildSecondary() => SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                safeSecondary,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: (isCompact ? text.bodyMedium : text.bodyLarge)?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );

          Widget buildFooter() => SizedBox(
            width: double.infinity,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMicro ? 10 : (isCompact ? 11 : 12),
                    vertical: isMicro ? 2 : (isCompact ? 3 : 4),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.outlineVariant.withAlpha(190),
                      width: tokens.strokeHairline,
                    ),
                    color: scheme.surfaceContainerHighest.withAlpha(36),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: isMicro ? 11 : (isCompact ? 12 : 13),
                        color: dotAccent,
                      ),
                      SizedBox(width: isMicro ? 5 : 7),
                      Text(
                        safeFooter,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: (isCompact ? text.labelSmall : text.labelMedium)
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: iconBox,
                      width: iconBox,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(iconRadius),
                      ),
                      child: Center(
                        child: Icon(
                          leadingIcon ?? Icons.dashboard_customize_outlined,
                          color: iconAccent,
                          size: iconSize,
                        ),
                      ),
                    ),
                    SizedBox(width: hGap),
                    Expanded(
                      child: Text(
                        safeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: (isCompact ? text.titleSmall : text.titleMedium)
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: vGap),
                if (constraints.hasBoundedHeight)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final bodyH = bodyConstraints.maxHeight;

                        // Reserve a small, bounded band for the footer so the
                        // pill can scale down in both axes. This prevents the
                        // sub-pixel RenderFlex overflows that show up on small
                        // devices and in widget tests.
                        final footerCap = hasFooter
                            ? (isMicro ? 18.0 : (isCompact ? 22.0 : 26.0))
                            : 0.0;
                        final footerH = hasFooter
                            ? math.min(footerCap, bodyH * 0.34)
                            : 0.0;
                        final mainH = math.max(0.0, bodyH - footerH);

                        // Avoid rounding issues by never inserting a gap that
                        // is larger than the space it sits in.
                        final effectiveMidGap = hasSecondary
                            ? math.min(midGap, math.max(0.0, mainH * 0.12))
                            : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: mainH,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    fit: FlexFit.tight,
                                    flex: hasSecondary ? 3 : 1,
                                    child: Center(child: buildPrimary()),
                                  ),
                                  if (hasSecondary) ...[
                                    SizedBox(height: effectiveMidGap),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      flex: 2,
                                      child: Center(child: buildSecondary()),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (hasFooter)
                              SizedBox(
                                height: footerH,
                                child: Center(child: buildFooter()),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                else ...[
                  buildPrimary(),
                  if (hasSecondary) ...[
                    SizedBox(height: midGap),
                    buildSecondary(),
                  ],
                  if (hasFooter) ...[SizedBox(height: vGap), buildFooter()],
                ],
              ],
            ),
          );
        },
      ),
    );

    return Semantics(
      label: safeTitle,
      hint: safeHint,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: card,
        ),
      ),
    );
  }
}
