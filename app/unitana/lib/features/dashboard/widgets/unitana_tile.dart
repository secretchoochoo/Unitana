import 'package:flutter/material.dart';

import '../../../theme/theme_extensions.dart';

class UnitanaTile extends StatelessWidget {
  final String title;
  final String primary;
  final String secondary;
  final String footer;
  final String? hint;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Gradient? backgroundGradient;

  const UnitanaTile({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.footer,
    this.hint,
    this.onTap,
    this.leadingIcon,
    this.backgroundGradient,
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
                  constraints.maxHeight <= 160) ||
              (constraints.maxWidth.isFinite && constraints.maxWidth <= 160);

          // Content sections are optional. When a section is empty, we omit it entirely.
          // This avoids RenderFlex overflows in tight tiles (147x147, etc.).
          final hasSecondary = safeSecondary.trim().isNotEmpty;
          final hasFooter = safeFooter.trim().isNotEmpty;

          // Compact tiles (147x147, etc.) need tighter metrics to avoid RenderFlex overflows.
          final pad = isCompact ? tokens.gutterXS * 0.70 : tokens.gutterS;
          final vGap = isCompact ? (tokens.gutterXS * 0.35) : tokens.gutterS;
          final hGap = isCompact ? (tokens.gutterXS * 0.50) : tokens.gutterS;
          final midGap = isCompact ? (tokens.gutterXS * 0.25) : tokens.gutterXS;

          final iconBox = isCompact ? 28.0 : 36.0;
          final iconRadius = isCompact ? 9.0 : 12.0;
          final iconSize = isCompact ? 15.0 : 18.0;

          final primarySize = isCompact ? 18.0 : 28.0;

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
                          color: scheme.primary,
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
                Text(
                  safePrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: text.headlineMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: primarySize,
                    height: 1.0,
                  ),
                ),
                if (hasSecondary) ...[
                  SizedBox(height: midGap),
                  Text(
                    safeSecondary,
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: (isCompact ? text.bodyMedium : text.bodyLarge)
                        ?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (hasFooter) ...[
                  if (constraints.maxHeight.isFinite)
                    const Spacer()
                  else
                    SizedBox(height: vGap),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: isCompact ? 7 : 8,
                        color: brand.accent,
                      ),
                      SizedBox(
                        width: isCompact
                            ? (tokens.gutterXS * 0.45)
                            : tokens.gutterXS,
                      ),
                      Expanded(
                        child: Text(
                          safeFooter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style:
                              (isCompact ? text.labelMedium : text.labelLarge)
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ),
                    ],
                  ),
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
        child: InkWell(onTap: onTap, borderRadius: borderRadius, child: card),
      ),
    );
  }
}
