import 'package:sensor_core/sensor_core.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// The shape of the plugin's sensor functions, each a stream of its events,
/// so that a test can hand in another.
typedef SensorEvents<E> = Stream<E> Function({Duration samplingPeriod});

/// The device's sensors, read through `sensors_plus`, each asked for a
/// reading every 20 ms. Android takes the period as a hint and usually
/// delivers faster.
class DeviceSensorService implements SensorService {
  /// A service over the plugin's accelerometer and gyroscope, or over what a
  /// test hands in.
  new({
    this._accelerometerEvents = accelerometerEventStream,
    this._gyroscopeEvents = gyroscopeEventStream,
  });

  final SensorEvents<AccelerometerEvent> _accelerometerEvents;
  final SensorEvents<GyroscopeEvent> _gyroscopeEvents;

  @override
  Stream<Reading> accelerometer() =>
      _accelerometerEvents(samplingPeriod: SensorInterval.gameInterval)
          .map((event) => Reading(x: event.x, y: event.y, z: event.z));

  @override
  Stream<Reading> gyroscope() =>
      _gyroscopeEvents(samplingPeriod: SensorInterval.gameInterval)
          .map((event) => Reading(x: event.x, y: event.y, z: event.z));
}
