import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/domain/sensed.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';

void main() {
  test('the view model keeps the latest list by key, newest first, the keys in '
      'the order they first appeared', () async {
    // A fake: the recent levels provider, overridden with two lists, the
    // second naming the gyroscope first.
    SensedLevel level(String keyExpr, int second) => (
      sensor: sensorOf(keyExpr.split('/').last),
      level: SensorLevel(
        time: DateTime.utc(2026, 10, 11, 0, 50, second),
        keyExpr: keyExpr,
        level: 0.5,
      ),
    );
    const accel = 'sensor/phone/accel';
    const gyro = 'sensor/phone/gyro';
    final container = ProviderContainer.test(
      overrides: [
        recentLevelsProvider.overrideWith(
          (ref) => Stream.fromIterable([
            [level(accel, 1)],
            [level(gyro, 2), level(accel, 2), level(accel, 1)],
          ]),
        ),
      ],
    )..listen(recentViewModelProvider, (_, _) {});

    // Let the two lists flow through before reading the state.
    await pumpEventQueue();

    // The code to implement: the view model's state, the latest list by
    // key.
    final state = container.read(recentViewModelProvider);

    // The claim: the accelerometer first, as it first appeared, with its
    // two levels newest first, then the gyroscope with its one.
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in state.byKey.entries)
        [keyExpr, levels.map((l) => l.level.time.second).toList()],
    ];
    expect(byKey, [
      [
        accel,
        [2, 1],
      ],
      [
        gyro,
        [2],
      ],
    ]);
  });
}
