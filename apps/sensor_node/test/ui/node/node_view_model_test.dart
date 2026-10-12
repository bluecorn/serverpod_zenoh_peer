import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/node/node_view_model.dart';

void main() {
  test(
    'the view model keeps the latest reading and the count for each key',
    () async {
      // A fake: the readings provider, overridden with three readings on two
      // keys, so nothing below the view model is built.
      const first = Reading(
        sensor: accelerometer,
        number: 1,
        x: 0,
        y: 9.776,
        z: 0.812,
      );
      const second = Reading(sensor: gyroscope, number: 1, x: 0, y: 0, z: 0.5);
      const third = Reading(
        sensor: accelerometer,
        number: 2,
        x: 0,
        y: 0,
        z: 9.81,
      );
      final container = ProviderContainer.test(
        overrides: [
          readingsProvider.overrideWith(
            (ref) => Stream.fromIterable([
              (keyExpr: 'sensor/phone/accel', reading: first),
              (keyExpr: 'sensor/phone/gyro', reading: second),
              (keyExpr: 'sensor/phone/accel', reading: third),
            ]),
          ),
        ],
      )..listen(nodeViewModelProvider, (_, _) {});

      // Let the three readings flow through before reading the state.
      await pumpEventQueue();

      // The code to implement: the view model's state, a latest reading and
      // a count for each key it heard.
      final state = container.read(nodeViewModelProvider);

      // The claim: two readings counted on the accelerometer's key and the
      // third kept, one on the gyroscope's.
      final sensors = {
        for (final MapEntry(key: keyExpr, value: sensor)
            in state.sensors.entries)
          keyExpr: (
            latest: (sensor.latest.x, sensor.latest.y, sensor.latest.z),
            count: sensor.count,
          ),
      };
      expect(sensors, {
        'sensor/phone/accel': (latest: (0, 0, 9.81), count: 2),
        'sensor/phone/gyro': (latest: (0, 0, 0.5), count: 1),
      });
    },
  );

  test("in the monitor role the view model's readings are received, in the "
      'node role published', () async {
    // Fakes: the role, one container in each, and the readings provider with
    // nothing, so nothing below the view model is built.
    NodeState stateIn(NodeRole role) {
      final container = ProviderContainer.test(
        overrides: [
          nodeRoleProvider.overrideWithValue(role),
          readingsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      return container.read(nodeViewModelProvider);
    }

    // The code to implement: the view model's state, in each role.
    final receives = [
      stateIn(NodeRole.monitor).receives,
      stateIn(NodeRole.node).receives,
    ];

    // The claim: the monitor's readings are received, the node's are not.
    expect(receives, [true, false]);
  });
}
