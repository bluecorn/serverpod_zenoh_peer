import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/data/services/clock_service.dart';

class FakeSensorService implements SensorService {
  new(this.readings);

  final Stream<Reading> readings;

  @override
  Stream<Reading> accelerometer() => readings;

  @override
  Stream<Reading> gyroscope() => const Stream.empty();
}

class FakeClockService implements ClockService {
  new(this.seconds);

  final Stream<DateTime> seconds;

  @override
  Stream<DateTime> wholeSeconds() => seconds;
}
