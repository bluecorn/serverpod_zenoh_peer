import 'package:sensor_core/src/domain/raw_reading.dart';

/// The device's motion sensors, as the node reads them.
///
/// The accelerometer reports meters per second squared on three axes, gravity
/// included, so a device lying flat on its back reads about 9.81 on z. The
/// gyroscope reports radians per second about the same three axes, so a device
/// at rest reads 0 on each. The axes are the device's own, with the screen in
/// its natural orientation: x to the right, y towards the top, z out of the
/// screen.
abstract interface class SensorService {
  /// The accelerometer's readings, as the device delivers them.
  Stream<RawReading> accelerometer();

  /// The gyroscope's readings, as the device delivers them.
  Stream<RawReading> gyroscope();
}
