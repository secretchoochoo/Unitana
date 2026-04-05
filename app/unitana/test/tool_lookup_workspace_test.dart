import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/canonical_tools.dart';
import 'package:unitana/features/dashboard/models/tool_lookup_catalog.dart';
import 'package:unitana/features/dashboard/widgets/tool_lookup_surface.dart';
import 'package:unitana/features/dashboard/widgets/tool_lookup_workspace.dart';

void main() {
  ToolLookupSurfaceTheme buildTheme() {
    return const ToolLookupSurfaceTheme(
      accent: Colors.cyan,
      panelBg: Color(0xFF20232A),
      panelBorder: Color(0xFF44475A),
      textPrimary: Color(0xFFF8F8F2),
      textMuted: Color(0xFFB0B7C3),
      headingTone: Colors.purpleAccent,
      selectedTone: Colors.redAccent,
      successTone: Colors.greenAccent,
    );
  }

  String sanitize(String unit) =>
      unit.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  testWidgets('lookup workspace renders compact result and delegates actions', (
    tester,
  ) async {
    final rows = toolLookupEntriesFor(CanonicalToolId.shoeSizes);
    final row = rows.firstWhere((entry) => entry.keyId == 'shoe_9');
    var swapCount = 0;
    var resetCount = 0;
    var pickFromCount = 0;
    var pickToCount = 0;
    var pickEntryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolLookupWorkspace(
            toolId: 'shoe_sizes',
            canonicalToolId: CanonicalToolId.shoeSizes,
            isFullMatrix: false,
            isClothingLookupTool: false,
            hasCustomSelection: true,
            selectedRow: row,
            rows: rows,
            selectedClothingGroupKey: null,
            fromSystem: 'US Men',
            toSystem: 'EU',
            matrixPageIndex: 0,
            theme: buildTheme(),
            onPickFromSystem: () {
              pickFromCount += 1;
            },
            onPickToSystem: () {
              pickToCount += 1;
            },
            onSwapSystems: () {
              swapCount += 1;
            },
            onPickEntry: () {
              pickEntryCount += 1;
            },
            onResetSelection: () {
              resetCount += 1;
            },
            onMatrixPageChanged: (_) {},
            onSelectClothingGroup: (_) {},
            onSelectEntry: (_) {},
            onCopyValue:
                ({
                  required String value,
                  required String label,
                  required ToolLookupEntry row,
                  required String system,
                }) async {},
            lookupValue: (lookupRow, system) =>
                lookupRow.valuesBySystem[system] ?? '—',
            sanitizeUnitKey: sanitize,
          ),
        ),
      ),
    );

    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(const ValueKey('tool_lookup_result_shoe_sizes')),
          matching: find.byType(RichText),
        )
        .first;
    expect(resultRichTextFinder, findsOneWidget);
    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    final resultText = resultRichText.text.toPlainText();
    expect(resultText, contains('US Men: 9'));
    expect(resultText, contains('EU: 42'));

    await tester.tap(find.byKey(const ValueKey('tool_lookup_from_shoe_sizes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tool_lookup_to_shoe_sizes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tool_lookup_swap_shoe_sizes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tool_lookup_size_shoe_sizes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tool_units_reset_shoe_sizes')));
    await tester.pump();

    expect(pickFromCount, 1);
    expect(pickToCount, 1);
    expect(swapCount, 1);
    expect(pickEntryCount, 1);
    expect(resetCount, 1);
  });

  testWidgets('lookup workspace renders clothing matrix and delegates copy', (
    tester,
  ) async {
    final allRows = toolLookupEntriesFor(CanonicalToolId.clothingSizes);
    final visibleRows = toolLookupEntriesForGroup(
      canonicalToolId: CanonicalToolId.clothingSizes,
      rows: allRows,
      groupKey: 'women_tops',
    );
    final row = visibleRows.firstWhere(
      (entry) => entry.keyId == 'cloth_w_tops_s',
    );
    String selectedGroup = 'women_tops';
    String copiedValue = '';
    String copiedSystem = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolLookupWorkspace(
            toolId: 'clothing_sizes',
            canonicalToolId: CanonicalToolId.clothingSizes,
            isFullMatrix: true,
            isClothingLookupTool: true,
            hasCustomSelection: false,
            selectedRow: row,
            rows: visibleRows,
            selectedClothingGroupKey: selectedGroup,
            fromSystem: 'US',
            toSystem: 'EU',
            matrixPageIndex: 0,
            theme: buildTheme(),
            onPickFromSystem: () {},
            onPickToSystem: () {},
            onSwapSystems: () {},
            onPickEntry: () {},
            onResetSelection: () {},
            onMatrixPageChanged: (_) {},
            onSelectClothingGroup: (groupKey) {
              selectedGroup = groupKey;
            },
            onSelectEntry: (_) {},
            onCopyValue:
                ({
                  required String value,
                  required String label,
                  required ToolLookupEntry row,
                  required String system,
                }) async {
                  copiedValue = value;
                  copiedSystem = system;
                },
            lookupValue: (lookupRow, system) =>
                lookupRow.valuesBySystem[system] ?? '—',
            sanitizeUnitKey: sanitize,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_clothing_sizes')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('tool_lookup_group_chip_clothing_sizes_men_tops'),
      ),
    );
    await tester.pump();
    expect(selectedGroup, 'men_tops');

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tool_lookup_matrix_cell_clothing_sizes_cloth_w_tops_s_US',
        ),
      ),
    );
    await tester.pump();
    expect(copiedValue, row.valuesBySystem['US']);
    expect(copiedSystem, 'US');
  });
}
