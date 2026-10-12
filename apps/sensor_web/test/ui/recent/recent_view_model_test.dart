import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/domain/sensed.dart';
import 'package:sensor_web/ui/recent/recent_view_model.dart';

void main() {
  test('the view model keeps the latest list by key, newest first, the keys in '
      "the sensor list's order", () async {
    // A fake: the recent levels provider, overridden with two lists, the
    // gyroscope's level the newest in the second.
    SensedLevel level(String keyExpr, int second) => (
      sensor: sensorOf(keyExpr.split('/').last),
      level: SensorLevel(
        time: DateTime.utc(2026, 10, 12, 12, 0, second),
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
            [level(gyro, 1)],
            [level(gyro, 3), level(accel, 2), level(gyro, 1)],
          ]),
        ),
      ],
    )..listen(recentViewModelProvider, (_, _) {});
    await pumpEventQueue();

    // The code to implement: the view model's state, the latest list by key.
    final state = container.read(recentViewModelProvider);

    // The claim: the accelerometer first, as the list has it, then the
    // gyroscope with its two levels newest first.
    final byKey = [
      for (final MapEntry(key: keyExpr, value: levels) in state.byKey.entries)
        [keyExpr, levels.map((l) => l.level.time.second).toList()],
    ];
    expect(byKey, [
      [
        accel,
        [2],
      ],
      [
        gyro,
        [3, 1],
      ],
    ]);
  });
}
