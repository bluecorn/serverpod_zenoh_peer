import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The web door: the phone's readings, for browsers.
class WebDoorEndpoint extends Endpoint {
  /// Every reading the phone publishes while the caller listens, with its key
  /// and its number. Listening subscribes to the phone's readings; cancelling
  /// closes the subscription.
  Stream<SensorReading> readings(Session session) => serverContainer
      .read(readingsRepositoryProvider)
      .readings()
      .map(
        (keyed) => SensorReading(
          keyExpr: keyed.keyExpr,
          number: keyed.reading.number,
          x: keyed.reading.x,
          y: keyed.reading.y,
          z: keyed.reading.z,
          time: keyed.reading.time!,
        ),
      );

  /// The archive's last [n] levels, newest first: at once, and again each
  /// time a level is kept.
  Stream<List<SensorLevel>> recent(Session session, int n) async* {
    final archive = serverContainer.read(archiveRepositoryProvider);
    yield await archive.recent(session, n);
    await for (final _ in serverContainer.read(recorderProvider).kept) {
      yield await archive.recent(session, n);
    }
  }
}
