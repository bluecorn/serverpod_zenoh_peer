import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The web door: the phone's readings, for browsers.
class WebDoorEndpoint extends Endpoint {
  /// Every reading the phone publishes while the caller listens, with its key.
  /// Listening subscribes to the phone's readings; cancelling closes the
  /// subscription.
  Stream<SensorReading> readings(Session session) => serverContainer
      .read(readingsRepositoryProvider)
      .readings()
      .map(
        (keyed) => SensorReading(
          keyExpr: keyed.keyExpr,
          x: keyed.reading.x,
          y: keyed.reading.y,
          z: keyed.reading.z,
        ),
      );
}
