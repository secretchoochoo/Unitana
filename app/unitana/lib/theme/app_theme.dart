import 'package:flutter/material.dart';

/// App-wide theming. We use a Dracula-inspired dark palette everywhere and
/// intentionally do not expose a light mode toggle.
class UnitanaTheme {
  static ThemeData dark() {
    const background = Color(0xFF282A36);
    const currentLine = Color(0xFF44475A);
    const foreground = Color(0xFFF8F8F2);
    const comment = Color(0xFF6272A4);

    const purple = Color(0xFFBD93F9);
    const cyan = Color(0xFF8BE9FD);
    const green = Color(0xFF50FA7B);
    const red = Color(0xFFFF5555);

    final scheme = const ColorScheme.dark(
      primary: purple,
      onPrimary: Color(0xFF1B1D26),
      secondary: cyan,
      onSecondary: Color(0xFF1B1D26),
      tertiary: green,
      onTertiary: Color(0xFF1B1D26),
      error: red,
      onError: Color(0xFF1B1D26),
      surface: background,
      onSurface: foreground,
      surfaceContainerHighest: currentLine,
      onSurfaceVariant: foreground,
      outline: comment,
      outlineVariant: comment,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: currentLine,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dividerColor: comment.withAlpha(128),
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      iconTheme: const IconThemeData(color: foreground),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: const Color(0xFF1B1D26),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: comment.withAlpha(204)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: currentLine,
        contentTextStyle: TextStyle(color: foreground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: currentLine,
        hintStyle: TextStyle(color: foreground.withAlpha(166)),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: cyan),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: currentLine,
        labelStyle: const TextStyle(color: foreground),
        side: BorderSide(color: comment.withAlpha(153)),
        shape: const StadiumBorder(),
      ),
      extensions: const <ThemeExtension<dynamic>>[UnitanaThemeTokens()],
    );
  }

  /// Kept for compatibility; intentionally identical to [dark()].
  static ThemeData light() => dark();
}

/// Tiny set of reusable UI tokens.
@immutable
class UnitanaThemeTokens extends ThemeExtension<UnitanaThemeTokens> {
  const UnitanaThemeTokens({
    this.radiusLg = 20,
    this.radiusMd = 16,
    this.radiusSm = 12,
    this.gutter = 16,
  });

  final double radiusLg;
  final double radiusMd;
  final double radiusSm;
  final double gutter;

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  UnitanaThemeTokens copyWith({
    double? radiusLg,
    double? radiusMd,
    double? radiusSm,
    double? gutter,
  }) {
    return UnitanaThemeTokens(
      radiusLg: radiusLg ?? this.radiusLg,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusSm: radiusSm ?? this.radiusSm,
      gutter: gutter ?? this.gutter,
    );
  }

  @override
  UnitanaThemeTokens lerp(ThemeExtension<UnitanaThemeTokens>? other, double t) {
    if (other is! UnitanaThemeTokens) return this;
    return UnitanaThemeTokens(
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      gutter: _lerpDouble(gutter, other.gutter, t),
    );
  }
}

extension UnitanaThemeX on BuildContext {
  UnitanaThemeTokens get unitanaTokens =>
      Theme.of(this).extension<UnitanaThemeTokens>() ??
      const UnitanaThemeTokens();
}
