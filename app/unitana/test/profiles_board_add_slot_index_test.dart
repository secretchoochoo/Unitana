import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/widgets/profiles_board_screen.dart';

void main() {
  testWidgets(
    'profiles board add tile passes deterministic absolute slot index',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = UnitanaAppState(UnitanaStorage());
      await state.load();

      int? capturedSlotIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilesBoardScreen(
            state: state,
            onSwitchProfile: (_) async {},
            onEditProfile: (_) async {},
            onDeleteProfile: (_) async {},
            onAddProfile: ({int? slotIndex}) async {
              capturedSlotIndex = slotIndex;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With one profile, the first add tile should map to absolute index 1.
      final addTile = find.byKey(const Key('profiles_board_add_profile'));
      expect(addTile, findsOneWidget);
      await tester.tap(addTile);
      await tester.pumpAndSettle();

      expect(capturedSlotIndex, 1);
    },
  );
}
