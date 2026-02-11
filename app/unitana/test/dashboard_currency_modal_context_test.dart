import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

/// Verifies that the Currency tool's unit direction follows the active Places
/// Hero reality (Home vs Destination).
///
/// Contract:
/// - No text finders (tool title/order/localization should not be test deps)
/// - Stable keys only
/// - Home reality: HomeCurrency -> DestinationCurrency
/// - Destination reality: DestinationCurrency -> HomeCurrency
void main() {
  testWidgets(
    'Currency tool direction follows Places Hero reality (home vs destination)',
    (tester) async {
      await pumpDashboardForTest(tester);

      final homeSegment = find.byKey(const Key('places_hero_segment_home'));
      final destSegment = find.byKey(
        const Key('places_hero_segment_destination'),
      );
      expect(homeSegment, findsOneWidget);
      expect(destSegment, findsOneWidget);

      Future<void> openCurrencyTool() async {
        final toolsButton = find.byKey(
          const ValueKey('dashboard_tools_button'),
        );
        expect(toolsButton, findsOneWidget);
        await tester.tap(toolsButton);
        await tester.pumpAndSettle();

        // The ToolPicker groups tools under lenses; tests must not depend on
        // lens expansion order. Use the stable search field + results key.
        final searchField = find.byKey(const ValueKey('toolpicker_search'));
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'currency');
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        final result = find.byKey(
          const ValueKey('toolpicker_search_tool_currency_convert'),
        );
        if (result.evaluate().isNotEmpty) {
          await tester.tap(result);
        } else {
          // Fallback: direct row key (should only be needed if search results
          // section is not present for some reason).
          final fallback = find.byKey(
            const ValueKey('toolpicker_tool_currency_convert'),
          );
          expect(fallback, findsOneWidget);
          await tester.tap(fallback);
        }
        await tester.pumpAndSettle();
      }

      Future<List<String>> openAndReadCodes() async {
        await openCurrencyTool();

        final fromBtn = find.byKey(
          const ValueKey('tool_unit_from_currency_convert'),
        );
        final toBtn = find.byKey(
          const ValueKey('tool_unit_to_currency_convert'),
        );
        expect(fromBtn, findsOneWidget);
        expect(toBtn, findsOneWidget);

        String readCode(Finder button) {
          final codeText = find.descendant(
            of: button,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  RegExp(r'^[A-Z]{3}$').hasMatch((w.data ?? '').trim()),
            ),
          );
          expect(codeText, findsOneWidget);
          return (tester.widget<Text>(codeText).data ?? '').trim();
        }

        return [readCode(fromBtn), readCode(toBtn)];
      }

      Future<void> closeModal() async {
        // The tool UI is a modal bottom sheet. In widget tests, tapping the
        // center of a ModalBarrier can miss if the derived offset lands inside
        // the sheet. Prefer a deterministic tap near the top-left corner.
        final unitsFinder = find.byKey(
          const ValueKey('tool_unit_from_currency_convert'),
        );

        // If the sheet is already closed, no-op.
        if (unitsFinder.evaluate().isEmpty) return;

        for (var i = 0; i < 3; i++) {
          await tester.tapAt(const Offset(8, 8));
          await tester.pumpAndSettle();
          if (unitsFinder.evaluate().isEmpty) break;
        }

        expect(unitsFinder, findsNothing);
      }

      // Home selected: Denver (USD) -> Porto (EUR)
      await tester.tap(homeSegment);
      await tester.pumpAndSettle();
      final homeCodes = await openAndReadCodes();
      expect(homeCodes, equals(const ['USD', 'EUR']));
      await closeModal();

      // Destination selected: Porto (EUR) -> Denver (USD)
      await tester.tap(destSegment);
      await tester.pumpAndSettle();
      final destCodes = await openAndReadCodes();
      expect(destCodes, equals(const ['EUR', 'USD']));
      await closeModal();
    },
  );

  testWidgets('Currency tool allows manual from/to currency selection', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    Future<void> openCurrencyTool() async {
      await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('toolpicker_search')),
        'currency',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      await tester.tap(
        find.byKey(const ValueKey('toolpicker_search_tool_currency_convert')),
      );
      await tester.pumpAndSettle();
    }

    String readCode(String buttonKey) {
      final button = find.byKey(ValueKey(buttonKey));
      expect(button, findsOneWidget);
      final code = find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              RegExp(r'^[A-Z]{3}$').hasMatch((w.data ?? '').trim()),
        ),
      );
      expect(code, findsOneWidget);
      return (tester.widget<Text>(code).data ?? '').trim();
    }

    Future<void> pickCurrency({
      required String buttonKey,
      required String side,
      required String code,
    }) async {
      final button = find.byKey(ValueKey(buttonKey));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();

      final pickerList = find.byKey(
        ValueKey('tool_unit_picker_currency_convert_$side'),
      );
      expect(pickerList, findsOneWidget);

      final itemKey = ValueKey('tool_unit_item_currency_convert_${side}_$code');
      final item = find.byKey(itemKey);
      var found = item.evaluate().isNotEmpty;
      for (var i = 0; i < 120 && !found; i++) {
        await tester.drag(pickerList, const Offset(0, -220));
        await tester.pumpAndSettle();
        found = item.evaluate().isNotEmpty;
      }
      expect(item, findsOneWidget);
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    await openCurrencyTool();

    await pickCurrency(
      buttonKey: 'tool_unit_from_currency_convert',
      side: 'from',
      code: 'AUD',
    );
    await pickCurrency(
      buttonKey: 'tool_unit_to_currency_convert',
      side: 'to',
      code: 'CAD',
    );

    expect(readCode('tool_unit_from_currency_convert'), 'AUD');
    expect(readCode('tool_unit_to_currency_convert'), 'CAD');
  });
}
