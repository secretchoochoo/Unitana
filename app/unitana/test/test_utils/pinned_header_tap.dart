import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Safely taps a target in a scroll view that uses a pinned header.
///
/// Widget tests can miss hit tests when the target is technically "visible"
/// but still occluded by a pinned sliver header.
///
/// This helper:
/// - Scrolls the target into view with a bottom-biased alignment.
/// - If an [obstruction] is provided and overlaps the target, it re-aligns
///   closer to the bottom.
/// - Taps the target and pumps a short frame.
Future<void> safeTapPinned(
  WidgetTester tester,
  Finder target, {
  Finder? obstruction,
  double minGap = 8,
}) async {
  // Ensure something exists before attempting alignment.
  if (target.evaluate().isEmpty) return;

  Future<void> align(double alignment) async {
    final element = target.evaluate().first;
    await Scrollable.ensureVisible(
      element,
      alignment: alignment,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  // First pass: land the target away from the pinned top region.
  await align(0.90);

  if (obstruction != null && obstruction.evaluate().isNotEmpty) {
    final oRect = tester.getRect(obstruction);
    final tRect = tester.getRect(target);

    // If the pinned header still overlaps the target, push the target closer
    // to the bottom edge.
    if (tRect.top < (oRect.bottom + minGap)) {
      await align(1.0);
    }
  }

  await tester.tap(target);
  await tester.pump();
}
