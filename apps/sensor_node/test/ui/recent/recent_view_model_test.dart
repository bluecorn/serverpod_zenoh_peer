import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

void main() {
  test('the panel keeps the newest 20 levels in all, the oldest leaving as a '
      'new one arrives', () async {
    // Fakes: the history provider, overridden with twenty levels newest
    // first, nineteen on the accelerometer's key and the oldest on the
    // gyroscope's, and the live provider with a stream the test plays.
    KeyedLevel level(String keyExpr, int second) => (
      keyExpr: keyExpr,
      level: Level(
        sensor: keyExpr.endsWith('gyro') ? gyroscope : accelerometer,
        time: DateTime.utc(2026, 10, 11, 0, 50, second),
        value: 0.5,
      ),
    );
    const accel = 'archive/phone/accel';
    const gyro = 'archive/phone/gyro';
    final live = StreamController<KeyedLevel>();
    addTearDown(live.close);
    final container = ProviderContainer.test(
      overrides: [
        recentLevelsProvider.overrideWith(
          (ref) async => [
            for (var second = 20; second >= 2; second--) level(accel, second),
            level(gyro, 1),
          ],
        ),
        liveLevelsProvider.overrideWith((ref) => live.stream),
      ],
    )..listen(recentViewModelProvider, (_, _) {});
    await pumpEventQueue();

    // The code to implement: a twenty-first level, published on the
    // accelerometer's key, newer than every other.
    live.add(level(accel, 21));
    await pumpEventQueue();
    final state = container.read(recentViewModelProvider);

    // The claim: the accelerometer's twenty newest levels, and the gyroscope
    // gone with the oldest.
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in state.byKey.entries)
        [keyExpr, levels.map((l) => l.time.second).toList()],
    ];
    expect(byKey, [
      [
        accel,
        [for (var second = 21; second >= 2; second--) second],
      ],
    ]);
  });

  test("the panel's view model shows the history, then each published level "
      "on top, the keys in the sensor list's order", () async {
    // Fakes: the history provider, overridden with three levels newest first,
    // the gyroscope's the newest, and the live provider with a stream the
    // test plays.
    KeyedLevel level(String keyExpr, int second) => (
      keyExpr: keyExpr,
      level: Level(
        sensor: keyExpr.endsWith('gyro') ? gyroscope : accelerometer,
        time: DateTime.utc(2026, 10, 12, 12, 0, second),
        value: 0.5,
      ),
    );
    const accel = 'archive/phone/accel';
    const gyro = 'archive/phone/gyro';
    final live = StreamController<KeyedLevel>();
    addTearDown(live.close);
    final container = ProviderContainer.test(
      overrides: [
        recentLevelsProvider.overrideWith(
          (ref) async => [level(gyro, 4), level(accel, 3), level(gyro, 2)],
        ),
        liveLevelsProvider.overrideWith((ref) => live.stream),
      ],
    )..listen(recentViewModelProvider, (_, _) {});
    await pumpEventQueue();

    // The code to implement: the history shown, then a level published on
    // the accelerometer's key, newer than every other.
    live.add(level(accel, 5));
    await pumpEventQueue();
    final state = container.read(recentViewModelProvider);

    // The claim: the accelerometer first, as the list has it, with the
    // published level above its history, then the gyroscope with its two
    // levels newest first.
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in state.byKey.entries)
        [keyExpr, levels.map((l) => l.time.second).toList()],
    ];
    expect(byKey, [
      [
        accel,
        [5, 3],
      ],
      [
        gyro,
        [4, 2],
      ],
    ]);
  });
}
