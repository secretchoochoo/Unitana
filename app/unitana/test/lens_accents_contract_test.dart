import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/activity_lenses.dart';
import 'package:unitana/features/dashboard/models/lens_accents.dart';
import 'package:unitana/theme/dracula_palette.dart';

void main() {
  test('Weather & Time lens uses calm slate accent (not yellow)', () {
    final color = LensAccents.colorFor(ActivityLensId.weatherTime);
    expect(color, DraculaPalette.comment);
    expect(color, isNot(DraculaPalette.yellow));
  });

  test('Travel and Health accents use muted tones in light mode', () {
    final travel = LensAccents.colorForBrightness(
      ActivityLensId.travelEssentials,
      Brightness.light,
    );
    final health = LensAccents.colorForBrightness(
      ActivityLensId.healthFitness,
      Brightness.light,
    );
    expect(travel, const Color(0xFF3D7194));
    expect(health, const Color(0xFF627228));
  });

  test('Shoes tool icon uses muted red override in light mode', () {
    final shoes = LensAccents.toolIconTintForBrightness(
      toolId: 'shoe_sizes',
      lensId: ActivityLensId.quickTools,
      brightness: Brightness.light,
    );
    expect(shoes, const Color(0xFFB95A5A).withValues(alpha: 0.88));
  });
}
