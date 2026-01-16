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

        final unitsFinder = find.byKey(
          const ValueKey('tool_units_currency_convert'),
        );
        expect(unitsFinder, findsOneWidget);

        final label = tester.widget<Text>(unitsFinder).data ?? '';

        // Extract a 2-code pair like "EUR ↔ USD" (order matters).
        final codes = RegExp(
          r'\b[A-Z]{3}\b',
        ).allMatches(label).map((m) => m.group(0)!).toList();
        expect(
          codes.length,
          2,
          reason:
              'Expected exactly two currency codes in units label, got: $label',
        );
        return codes;
      }

      Future<void> closeModal() async {
        // The tool UI is a modal bottom sheet. In widget tests, tapping the
        // center of a ModalBarrier can miss if the derived offset lands inside
        // the sheet. Prefer a deterministic tap near the top-left corner.
        final unitsFinder = find.byKey(
          const ValueKey('tool_units_currency_convert'),
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
}
