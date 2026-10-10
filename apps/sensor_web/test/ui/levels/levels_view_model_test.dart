import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_web/config/providers.dart';
import 'package:sensor_web/ui/levels/levels_view_model.dart';

void main() {
  test('the view model keeps the latest level on each key', () async {
    // A fake: the levels provider, overridden with three levels on two keys,
    // so nothing below the view model is built.
    const accel = 'sensor/phone/accel';
    const gyro = 'sensor/phone/gyro';
    final first = DateTime.utc(2026, 10, 10, 12, 0, 1);
    final next = first.add(const Duration(seconds: 1));
    final container = ProviderContainer.test(
      overrides: [
        levelsProvider.overrideWith(
          (ref) => Stream.fromIterable([
            SensorLevel(time: first, keyExpr: accel, level: 2.5),
            SensorLevel(time: first, keyExpr: gyro, level: 1),
            SensorLevel(time: next, keyExpr: accel, level: 3),
          ]),
        ),
      ],
    )..listen(levelsViewModelProvider, (_, _) {});

    // Let the three levels flow through before reading the state.
    await pumpEventQueue();

    // The code to implement: the view model's state, the latest level on each
    // key it heard.
    final state = container.read(levelsViewModelProvider);

    // The claim: the accelerometer's second level replaced its first, and the
    // gyroscope's one level kept.
    final latest = {
      for (final MapEntry(key: keyExpr, value: level) in state.latest.entries)
        keyExpr: (level.time, level.level),
    };
    expect(latest, {accel: (next, 3.0), gyro: (first, 1.0)});
  });
}
