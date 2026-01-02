import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/dracula_palette.dart';

enum UnitanaNoticeKind { success, info, error }

/// Small, reusable notice surface used for transient confirmations and errors.
///
/// Styled to be readable and restrained on the Dracula-inspired dark theme.
class UnitanaNoticeCard extends StatelessWidget {
  const UnitanaNoticeCard({
    super.key,
    required this.text,
    this.kind = UnitanaNoticeKind.success,
    this.compact = true,
  });

  final String text;
  final UnitanaNoticeKind kind;
  final bool compact;

  Color get _accent => switch (kind) {
    UnitanaNoticeKind.success => DraculaPalette.green,
    UnitanaNoticeKind.info => DraculaPalette.cyan,
    UnitanaNoticeKind.error => DraculaPalette.red,
  };

  IconData get _icon => switch (kind) {
    UnitanaNoticeKind.success => Icons.check_circle_outline_rounded,
    UnitanaNoticeKind.info => Icons.info_outline_rounded,
    UnitanaNoticeKind.error => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.unitanaTokens;
    final scheme = Theme.of(context).colorScheme;
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: _accent.withAlpha(140)),
      ),
      child: Padding(
        padding: pad,
        child: Row(
          children: [
            Icon(_icon, color: _accent),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
