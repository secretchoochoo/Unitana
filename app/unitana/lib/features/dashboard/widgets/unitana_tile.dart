import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/theme_extensions.dart';

class UnitanaTile extends StatelessWidget {
  final String title;
  final String primary;
  final String secondary;
  final String footer;
  final String? primaryDeemphasizedPrefix;
  final String? hint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? leadingIcon;
  final Gradient? backgroundGradient;
  final Key? interactionKey;

  /// Optional accent override used for icon + footer cue coloring.
  ///
  /// When null, the tile falls back to the app's default accent behavior.
  final Color? accentColor;
  final bool compactValues;
  final double valuesTopInset;

  const UnitanaTile({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.footer,
    this.primaryDeemphasizedPrefix,
    this.hint,
    this.onTap,
    this.onLongPress,
    this.leadingIcon,
    this.backgroundGradient,
    this.accentColor,
    this.interactionKey,
    this.compactValues = false,
    this.valuesTopInset = 0,
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

          final primarySizeBase = isMicro ? 16.0 : (isCompact ? 18.0 : 28.0);
          final primarySize = compactValues
              ? (primarySizeBase * 0.82)
              : primarySizeBase;

          final hasSecondary = safeSecondary.trim().isNotEmpty && !isMicro;
          final hasFooter = safeFooter.trim().isNotEmpty;

          final boundedWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : null;

          Widget buildPrimary() => SizedBox(
            width: boundedWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: () {
                final baseStyle = text.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: primarySize,
                  height: 1.0,
                );
                final prefix = primaryDeemphasizedPrefix?.trim();
                final hasPrefix =
                    prefix != null &&
                    prefix.isNotEmpty &&
                    safePrimary.startsWith(prefix);

                if (!hasPrefix) {
                  return Text(
                    safePrimary,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: baseStyle,
                  );
                }

                final rest = safePrimary.substring(prefix.length);
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: prefix,
                        style: baseStyle?.copyWith(
                          fontSize: primarySize * 0.58,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withAlpha(210),
                        ),
                      ),
                      TextSpan(text: rest, style: baseStyle),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                );
              }(),
            ),
          );

          Widget buildSecondary() => SizedBox(
            width: boundedWidth,
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
            width: boundedWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMicro ? 8 : (isCompact ? 9 : 10),
                    vertical: isMicro ? 1.5 : (isCompact ? 2.0 : 3.0),
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
                        size: isMicro ? 10 : (isCompact ? 11 : 12),
                        color: dotAccent,
                      ),
                      SizedBox(width: isMicro ? 4 : (isCompact ? 5 : 6)),
                      Text(
                        safeFooter,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: isMicro ? 10.0 : (isCompact ? 11.0 : 11.5),
                          height: 1.0,
                          letterSpacing: 0.10,
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
                SizedBox(
                  height: iconBox,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
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
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: iconBox + hGap,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              safeTitle,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style:
                                  ((isCompact
                                                  ? text.titleSmall
                                                  : text.titleMedium)
                                              ?.copyWith(
                                                color: scheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ) ??
                                          const TextStyle())
                                      .merge(GoogleFonts.robotoSlab()),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                            ? (isMicro ? 16.0 : (isCompact ? 19.0 : 22.0))
                            : 0.0;
                        final footerH = hasFooter
                            ? math.min(footerCap, bodyH * 0.30)
                            : 0.0;
                        final mainH = math.max(0.0, bodyH - footerH);

                        // Avoid rounding issues by never inserting a gap that
                        // is larger than the space it sits in.
                        final effectiveMidGap = hasSecondary
                            ? math.min(midGap, math.max(0.0, mainH * 0.12))
                            : 0.0;
                        final editExtraGap = compactValues
                            ? math.min(9.0, math.max(3.0, mainH * 0.11))
                            : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: mainH,
                              child: Padding(
                                // Nudge the secondary line up a hair so the
                                // footer pill has a little more breathing
                                // room on compact tiles.
                                padding: EdgeInsets.only(
                                  top: valuesTopInset,
                                  bottom: isMicro
                                      ? 1.0
                                      : (isCompact ? 2.0 : 3.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      fit: FlexFit.tight,
                                      flex: hasSecondary ? 3 : 1,
                                      child: Center(child: buildPrimary()),
                                    ),
                                    if (hasSecondary) ...[
                                      SizedBox(
                                        height: effectiveMidGap + editExtraGap,
                                      ),
                                      Flexible(
                                        fit: FlexFit.tight,
                                        flex: 2,
                                        child: Center(child: buildSecondary()),
                                      ),
                                    ],
                                  ],
                                ),
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
          key: interactionKey,
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: card,
        ),
      ),
    );
  }
}
