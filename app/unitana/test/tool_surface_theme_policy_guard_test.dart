import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool surfaces keep Dracula literals behind theme policy adapters', () {
    final toolModal = File(
      'lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart',
    ).readAsLinesSync();
    final weatherSheet = File(
      'lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart',
    ).readAsLinesSync();

    final toolViolations = <String>[];
    var inToolPolicy = false;
    var toolPolicyBraceDepth = 0;
    for (var i = 0; i < toolModal.length; i++) {
      final line = toolModal[i];
      if (line.contains('class _ToolModalThemePolicy')) {
        inToolPolicy = true;
        toolPolicyBraceDepth = 0;
      }
      if (inToolPolicy) {
        toolPolicyBraceDepth += _braceDelta(line);
        if (toolPolicyBraceDepth <= 0 && line.contains('}')) {
          inToolPolicy = false;
        }
      }
      if (!line.contains('DraculaPalette.')) continue;
      final allowFallbackMapLane = line.contains('DraculaPalette.yellow');
      if (!inToolPolicy && !allowFallbackMapLane) {
        toolViolations.add('line ${i + 1}: ${line.trim()}');
      }
    }

    final weatherViolations = <String>[];
    var inWeatherPolicy = false;
    var weatherPolicyBraceDepth = 0;
    for (var i = 0; i < weatherSheet.length; i++) {
      final line = weatherSheet[i];
      if (line.contains('class _WeatherSheetThemePolicy')) {
        inWeatherPolicy = true;
        weatherPolicyBraceDepth = 0;
      }
      if (inWeatherPolicy) {
        weatherPolicyBraceDepth += _braceDelta(line);
        if (weatherPolicyBraceDepth <= 0 && line.contains('}')) {
          inWeatherPolicy = false;
        }
      }
      if (!line.contains('DraculaPalette.')) continue;
      if (!inWeatherPolicy) {
        weatherViolations.add('line ${i + 1}: ${line.trim()}');
      }
    }

    expect(
      toolViolations,
      isEmpty,
      reason:
          'Direct DraculaPalette usage found outside _ToolModalThemePolicy:\n'
          '${toolViolations.join('\n')}',
    );
    expect(
      weatherViolations,
      isEmpty,
      reason:
          'Direct DraculaPalette usage found outside _WeatherSheetThemePolicy:\n'
          '${weatherViolations.join('\n')}',
    );
  });
}

int _braceDelta(String line) {
  final opens = '{'.allMatches(line).length;
  final closes = '}'.allMatches(line).length;
  return opens - closes;
}
