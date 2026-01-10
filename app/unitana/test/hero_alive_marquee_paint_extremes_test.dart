import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/widgets/hero_alive_marquee.dart';

String _sceneLabel(SceneKey key) {
  final s = key.toString();
  final dot = s.lastIndexOf('.');
  return dot == -1 ? s : s.substring(dot + 1);
}

void main() {
  testWidgets(
    'HeroAliveMarquee paints key SceneKey extremes without exceptions',
    (tester) async {
      final extremes = <SceneKey>[
        SceneKey.clear,
        SceneKey.partlyCloudy,
        SceneKey.overcast,
        SceneKey.rainModerate,
        SceneKey.thunderRain,
        SceneKey.snowHeavy,
        SceneKey.fog,
        SceneKey.smokeWildfire,
        SceneKey.tornado,
      ];

      for (final isNight in <bool>[false, true]) {
        for (final sceneKey in extremes) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 260,
                    height: 80,
                    child: HeroAliveMarquee(
                      compact: true,
                      isNight: isNight,
                      sceneKey: sceneKey,
                      conditionLabel: _sceneLabel(sceneKey),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 120));
        }
      }
    },
  );
}
