import 'package:flutter/material.dart';

@immutable
class UnitanaLayoutTokens extends ThemeExtension<UnitanaLayoutTokens> {
  final double radiusCard;
  final double radiusButton;
  final double radiusSheet;

  final EdgeInsets pagePaddingPhone;
  final EdgeInsets pagePaddingTablet;

  final EdgeInsets tilePadding;
  final double gridGap;

  const UnitanaLayoutTokens({
    required this.radiusCard,
    required this.radiusButton,
    required this.radiusSheet,
    required this.pagePaddingPhone,
    required this.pagePaddingTablet,
    required this.tilePadding,
    required this.gridGap,
  });

  static const UnitanaLayoutTokens softGeometry = UnitanaLayoutTokens(
    radiusCard: 20,
    radiusButton: 16,
    radiusSheet: 24,
    pagePaddingPhone: EdgeInsets.all(16),
    pagePaddingTablet: EdgeInsets.all(24),
    tilePadding: EdgeInsets.all(16),
    gridGap: 12,
  );

  // Compatibility aliases used by newer UI widgets.
  // These map to the existing token set so older screens keep working.
  double get cornerRadiusL => radiusCard;
  double get cornerRadiusM => radiusButton;

  // Spacing scale (in logical pixels).
  double get gutterXS => 8;
  double get gutterS => 12;
  double get gutterM => 16;

  // Border widths.
  double get strokeHairline => 1;

  @override
  UnitanaLayoutTokens copyWith({
    double? radiusCard,
    double? radiusButton,
    double? radiusSheet,
    EdgeInsets? pagePaddingPhone,
    EdgeInsets? pagePaddingTablet,
    EdgeInsets? tilePadding,
    double? gridGap,
  }) {
    return UnitanaLayoutTokens(
      radiusCard: radiusCard ?? this.radiusCard,
      radiusButton: radiusButton ?? this.radiusButton,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      pagePaddingPhone: pagePaddingPhone ?? this.pagePaddingPhone,
      pagePaddingTablet: pagePaddingTablet ?? this.pagePaddingTablet,
      tilePadding: tilePadding ?? this.tilePadding,
      gridGap: gridGap ?? this.gridGap,
    );
  }

  @override
  UnitanaLayoutTokens lerp(
    ThemeExtension<UnitanaLayoutTokens>? other,
    double t,
  ) {
    if (other is! UnitanaLayoutTokens) return this;
    return UnitanaLayoutTokens(
      radiusCard: _lerpDouble(radiusCard, other.radiusCard, t),
      radiusButton: _lerpDouble(radiusButton, other.radiusButton, t),
      radiusSheet: _lerpDouble(radiusSheet, other.radiusSheet, t),
      pagePaddingPhone:
          EdgeInsets.lerp(pagePaddingPhone, other.pagePaddingPhone, t) ??
          pagePaddingPhone,
      pagePaddingTablet:
          EdgeInsets.lerp(pagePaddingTablet, other.pagePaddingTablet, t) ??
          pagePaddingTablet,
      tilePadding:
          EdgeInsets.lerp(tilePadding, other.tilePadding, t) ?? tilePadding,
      gridGap: _lerpDouble(gridGap, other.gridGap, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

@immutable
class UnitanaBrandTokens extends ThemeExtension<UnitanaBrandTokens> {
  final Color canvas;
  final LinearGradient brandGradient;

  const UnitanaBrandTokens({required this.canvas, required this.brandGradient});

  static const Color unitanaBlue = Color(0xFF6D9AFE);
  static const Color unitanaIndigo = Color(0xFF574ADE);
  static const Color unitanaViolet = Color(0xFFBA38BE);
  static const Color unitanaPink = Color(0xFFF568CA);

  static const UnitanaBrandTokens light = UnitanaBrandTokens(
    canvas: Color(0xFFF5E6DC),
    brandGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [unitanaBlue, unitanaIndigo, unitanaViolet, unitanaPink],
      stops: [0.0, 0.33, 0.66, 1.0],
    ),
  );

  static const UnitanaBrandTokens dark = UnitanaBrandTokens(
    canvas: Color(0xFF0E1016),
    brandGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [unitanaBlue, unitanaIndigo, unitanaViolet, unitanaPink],
      stops: [0.0, 0.33, 0.66, 1.0],
    ),
  );

  // Primary accent used for icons/indicators when a single color is needed.
  Color get accent => brandGradient.colors.isNotEmpty
      ? brandGradient.colors.first
      : unitanaBlue;

  @override
  UnitanaBrandTokens copyWith({Color? canvas, LinearGradient? brandGradient}) {
    return UnitanaBrandTokens(
      canvas: canvas ?? this.canvas,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  UnitanaBrandTokens lerp(ThemeExtension<UnitanaBrandTokens>? other, double t) {
    if (other is! UnitanaBrandTokens) return this;
    return UnitanaBrandTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      brandGradient:
          LinearGradient.lerp(brandGradient, other.brandGradient, t) ??
          brandGradient,
    );
  }
}
