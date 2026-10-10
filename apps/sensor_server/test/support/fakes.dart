import 'package:sensor_core/sensor_core.dart';

class FakeSensorService implements SensorService {
  new(this.readings);

  final Stream<Reading> readings;

  @override
  Stream<Reading> accelerometer() => readings;

  @override
  Stream<Reading> gyroscope() => const Stream.empty();
}
