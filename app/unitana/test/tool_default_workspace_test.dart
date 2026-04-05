import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/models/numeric_input_policy.dart';
import 'package:unitana/features/dashboard/widgets/tool_default_surface.dart';
import 'package:unitana/features/dashboard/widgets/tool_default_workspace.dart';

void main() {
  ToolDefaultSurfaceTheme buildTheme() {
    return const ToolDefaultSurfaceTheme(
      accent: Colors.cyan,
      textPrimary: Color(0xFFF8F8F2),
      textMuted: Color(0xFFB0B7C3),
      panelBg: Color(0xFF20232A),
      panelBorder: Color(0xFF44475A),
      headingTone: Colors.purpleAccent,
      warningTone: Colors.orangeAccent,
      successTone: Colors.greenAccent,
    );
  }

  testWidgets(
    'default workspace renders converter shell and delegates actions',
    (tester) async {
      final controller = TextEditingController(text: '5');
      var runCount = 0;
      var swapCount = 0;
      var resetCount = 0;
      var addCount = 0;
      var pickFromCount = 0;
      var pickToCount = 0;
      var copyResultCount = 0;
      var copyInputCount = 0;
      var clearCount = 0;

      final history = <ConversionRecord>[
        ConversionRecord(
          toolId: 'distance',
          fromUnit: 'km',
          toUnit: 'mi',
          inputLabel: '5 km',
          outputLabel: '3.11 mi',
          timestamp: DateTime.utc(2026, 4, 4, 12, 30),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolDefaultWorkspace(
              toolId: 'distance',
              controller: controller,
              requiresFreeformInput: false,
              numericPolicy: ToolNumericPolicies.forToolId('distance'),
              inputHint: '5',
              helperText: 'Enter a distance to convert.',
              supportsUnitPicker: true,
              fromUnit: 'km',
              toUnit: 'mi',
              showBakingHint: false,
              hasCustomUnitSelection: true,
              canAddWidget: true,
              theme: buildTheme(),
              editValueLabel: 'Edit value',
              convertLabel: 'Convert',
              addWidgetLabel: 'Add Widget',
              resetDefaultsLabel: 'Reset defaults',
              resultLine: '5 km → 3.11 mi',
              history: history,
              historyTitle: 'History',
              historyCopyHint: 'Tap to copy result',
              clearHistoryLabel: 'Clear history',
              emptyHistoryLabel: 'No history yet.',
              resultPlaceholderInput: 'Type a value',
              resultPlaceholderOutput: 'Converted result',
              onRunConversion: () {
                runCount += 1;
              },
              onSwapUnits: () {
                swapCount += 1;
              },
              onPickFromUnit: () {
                pickFromCount += 1;
              },
              onPickToUnit: () {
                pickToCount += 1;
              },
              onResetDefaults: () {
                resetCount += 1;
              },
              onAddWidget: () {
                addCount += 1;
              },
              onCopyResult: (_) async {
                copyResultCount += 1;
              },
              onCopyInput: (_) async {
                copyInputCount += 1;
              },
              onClearHistory: () async {
                clearCount += 1;
              },
              extraSections: const <Widget>[Text('Extra planning section')],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('tool_input_distance')), findsOneWidget);
      expect(find.text('Extra planning section'), findsOneWidget);

      final resultRichTextFinder = find
          .descendant(
            of: find.byKey(const ValueKey('tool_result_distance')),
            matching: find.byType(RichText),
          )
          .first;
      expect(resultRichTextFinder, findsOneWidget);
      final resultRichText = tester.widget<RichText>(resultRichTextFinder);
      final resultText = resultRichText.text.toPlainText();
      expect(resultText, contains('5 km'));
      expect(resultText, contains('3.11 mi'));

      await tester.tap(find.byKey(const ValueKey('tool_add_widget_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_unit_from_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_unit_to_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_swap_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_units_reset_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_run_distance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool_history_distance_0')));
      await tester.pump();
      await tester.longPress(
        find.byKey(const ValueKey('tool_history_distance_0')),
      );
      await tester.pump();
      await tester.tap(find.text('Clear history'));
      await tester.pump();

      expect(addCount, 1);
      expect(pickFromCount, 1);
      expect(pickToCount, 1);
      expect(swapCount, 1);
      expect(resetCount, 1);
      expect(runCount, 1);
      expect(copyResultCount, 1);
      expect(copyInputCount, 1);
      expect(clearCount, 1);
    },
  );
}
