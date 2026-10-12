import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/recent/recent_view_model.dart';

void main() {
  test("the panel's view model shows the history, then each published level "
      'on top, the keys in the order they first appeared', () async {
    // Fakes: the history provider, overridden with three levels newest first,
    // the accelerometer's the newest, and the live provider with a stream the
    // test plays.
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
          (ref) async => [level(accel, 4), level(gyro, 3), level(accel, 2)],
        ),
        liveLevelsProvider.overrideWith((ref) => live.stream),
      ],
    )..listen(recentViewModelProvider, (_, _) {});
    await pumpEventQueue();

    // The code to implement: the history shown, then a level published on
    // the gyroscope's key, newer than every other.
    live.add(level(gyro, 5));
    await pumpEventQueue();
    final state = container.read(recentViewModelProvider);

    // The claim: the accelerometer first, as it first appeared, with its two
    // levels newest first, then the gyroscope with the published level above
    // its history.
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in state.byKey.entries)
        [keyExpr, levels.map((l) => l.time.second).toList()],
    ];
    expect(byKey, [
      [
        accel,
        [4, 2],
      ],
      [
        gyro,
        [5, 3],
      ],
    ]);
  });

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
}
