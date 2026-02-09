import 'package:flutter/material.dart';

import 'dracula_palette.dart';

/// App-wide theming with Dracula dark + a light companion palette.
class UnitanaTheme {
  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: DraculaPalette.purple,
      onPrimary: Color(0xFF1B1D26),
      secondary: DraculaPalette.cyan,
      onSecondary: Color(0xFF1B1D26),
      tertiary: DraculaPalette.green,
      onTertiary: Color(0xFF1B1D26),
      error: DraculaPalette.red,
      onError: Color(0xFF1B1D26),
      surface: DraculaPalette.background,
      onSurface: DraculaPalette.foreground,
      surfaceContainerHighest: DraculaPalette.currentLine,
      onSurfaceVariant: DraculaPalette.foreground,
      outline: DraculaPalette.comment,
      outlineVariant: DraculaPalette.comment,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: DraculaPalette.background,
        foregroundColor: DraculaPalette.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: DraculaPalette.currentLine,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dividerColor: DraculaPalette.comment.withAlpha(128),
      textTheme: base.textTheme.apply(
        bodyColor: DraculaPalette.foreground,
        displayColor: DraculaPalette.foreground,
      ),
      iconTheme: const IconThemeData(color: DraculaPalette.foreground),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DraculaPalette.purple,
          foregroundColor: const Color(0xFF1B1D26),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DraculaPalette.foreground,
          side: BorderSide(color: DraculaPalette.comment.withAlpha(204)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: DraculaPalette.currentLine,
        contentTextStyle: TextStyle(color: DraculaPalette.foreground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DraculaPalette.currentLine,
        hintStyle: TextStyle(color: DraculaPalette.foreground.withAlpha(166)),
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
          borderSide: BorderSide(color: DraculaPalette.cyan),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DraculaPalette.currentLine,
        labelStyle: const TextStyle(color: DraculaPalette.foreground),
        side: BorderSide(color: DraculaPalette.comment.withAlpha(153)),
        shape: const StadiumBorder(),
      ),
      extensions: const <ThemeExtension<dynamic>>[UnitanaThemeTokens()],
    );
  }

  static ThemeData light() {
    const base03 = Color(0xFF002B36);
    const base02 = Color(0xFF073642);
    const base2 = Color(0xFFEEE8D5);
    const base3 = Color(0xFFFDF6E3);
    const blue = Color(0xFF268BD2);
    const cyan = Color(0xFF2AA198);
    const green = Color(0xFF859900);
    const orange = Color(0xFFCB4B16);
    const actionBlue = Color(0xFF3F7FAE);

    final scheme = const ColorScheme.light(
      primary: blue,
      onPrimary: base03,
      secondary: cyan,
      onSecondary: base03,
      tertiary: green,
      onTertiary: base03,
      error: orange,
      onError: base03,
      surface: base3,
      onSurface: base03,
      surfaceContainerHighest: base2,
      onSurfaceVariant: base02,
      outline: Color(0xFF93A1A1),
      outlineVariant: Color(0xFFB2B8AE),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: base3,
        foregroundColor: base03,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: base2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dividerColor: scheme.outlineVariant,
      textTheme: base.textTheme.apply(bodyColor: base03, displayColor: base03),
      iconTheme: const IconThemeData(color: base03),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: base03,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base03,
          side: BorderSide(color: scheme.outline.withAlpha(210)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: base2,
        contentTextStyle: TextStyle(color: base03),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base2,
        hintStyle: const TextStyle(color: base02),
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
          borderSide: BorderSide(color: blue),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: base2,
        labelStyle: const TextStyle(color: base03),
        side: BorderSide(color: scheme.outline.withAlpha(190)),
        shape: const StadiumBorder(),
      ),
      extensions: const <ThemeExtension<dynamic>>[UnitanaThemeTokens()],
    );
  }
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
