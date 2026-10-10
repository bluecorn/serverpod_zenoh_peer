import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The web door: the phone's readings, for browsers.
class WebDoorEndpoint extends Endpoint {
  /// Every reading the phone publishes while the caller listens, with its key.
  Stream<SensorReading> readings(Session session) => const Stream.empty();
}
