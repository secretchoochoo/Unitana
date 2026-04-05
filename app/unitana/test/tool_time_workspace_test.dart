import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/time_zone_catalog.dart';
import 'package:unitana/features/dashboard/widgets/tool_time_surface.dart';
import 'package:unitana/features/dashboard/widgets/tool_time_workspace.dart';
import 'package:unitana/models/place.dart';

void main() {
  ToolTimeSurfaceTheme buildTheme() {
    return const ToolTimeSurfaceTheme(
      accent: Colors.cyan,
      panelBg: Color(0xFF20232A),
      panelBorder: Color(0xFF44475A),
      textPrimary: Color(0xFFF8F8F2),
      textMuted: Color(0xFFB0B7C3),
      headingTone: Colors.purpleAccent,
      infoTone: Colors.lightBlueAccent,
      warningTone: Colors.orangeAccent,
      successTone: Colors.greenAccent,
      dangerTone: Colors.redAccent,
    );
  }

  const home = Place(
    id: 'home',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    unitSystem: 'imperial',
    use24h: true,
  );

  const destination = Place(
    id: 'dest',
    type: PlaceType.visiting,
    name: 'Destination',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    unitSystem: 'metric',
    use24h: false,
  );

  const options = <TimeZoneOption>[
    (id: 'America/Denver', label: 'Denver, US', subtitle: 'America/Denver'),
    (id: 'Europe/Lisbon', label: 'Lisbon, PT', subtitle: 'Europe/Lisbon'),
  ];

  testWidgets('time workspace renders standard facts with dual clocks', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2026-06-01 12:00');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTimeWorkspace(
            toolId: 'time',
            home: home,
            destination: destination,
            prefer24h: true,
            isJetLagDeltaTool: false,
            isWorldClockMapTool: false,
            isTimeZoneConverterTool: false,
            showAddWidget: false,
            fromZoneId: 'America/Denver',
            toZoneId: 'Europe/Lisbon',
            fromDisplayLabelOverride: 'Denver, US',
            toDisplayLabelOverride: 'Lisbon, PT',
            options: options,
            history: const <ConversionRecord>[],
            timeConvertController: controller,
            resultLine: null,
            jetLagBedtimeMinutes: 23 * 60,
            jetLagWakeMinutes: 7 * 60,
            jetLagOverlapExpanded: false,
            jetLagTipsAutoRotateEnabled: true,
            jetLagTipIndex: 0,
            theme: buildTheme(),
            onPickFromZone: () {},
            onPickToZone: () {},
            onSwapZones: () {},
            onAddWidget: null,
            onRunConversion: () {},
            onClearHistory: null,
            onPickBedtime: () {},
            onPickWakeTime: () {},
            onExpandOverlap: null,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('tool_time_now_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_time_dual_analog_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_converter_card')),
      findsNothing,
    );
  });

  testWidgets('world time workspace renders map section without converter UI', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2026-06-01 12:00');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTimeWorkspace(
            toolId: 'world_clock_delta',
            home: home,
            destination: destination,
            prefer24h: false,
            isJetLagDeltaTool: false,
            isWorldClockMapTool: true,
            isTimeZoneConverterTool: false,
            showAddWidget: false,
            fromZoneId: 'America/Denver',
            toZoneId: 'Europe/Lisbon',
            fromDisplayLabelOverride: 'Denver, US',
            toDisplayLabelOverride: 'Lisbon, PT',
            options: options,
            history: const <ConversionRecord>[],
            timeConvertController: controller,
            resultLine: null,
            jetLagBedtimeMinutes: 23 * 60,
            jetLagWakeMinutes: 7 * 60,
            jetLagOverlapExpanded: false,
            jetLagTipsAutoRotateEnabled: false,
            jetLagTipIndex: 0,
            theme: buildTheme(),
            onPickFromZone: () {},
            onPickToZone: () {},
            onSwapZones: () {},
            onAddWidget: null,
            onRunConversion: () {},
            onClearHistory: null,
            onPickBedtime: () {},
            onPickWakeTime: () {},
            onExpandOverlap: null,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('tool_time_world_map_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_converter_card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('tool_time_history_list')), findsNothing);
  });
}
