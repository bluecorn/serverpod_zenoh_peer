import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';
import 'package:sensor_web/domain/sensed.dart';

/// The page's side of the web door: what the server streams to browsers, each
/// reading and level with its sensor.
class WebDoorRepository {
  /// A repository calling [webDoor], the generated client's endpoint.
  new(this.webDoor);

  /// The web door's endpoint in the generated client.
  final EndpointWebDoor webDoor;

  /// Every reading the phone publishes, with its sensor. Listening calls the
  /// web door; cancelling ends the call.
  Stream<SensedReading> readings() =>
      webDoor.readings().map((reading) => (sensor: _none, reading: reading));

  /// The archive's last [n] levels, newest first, each with its sensor: at
  /// once, and again each time the server keeps a level. Listening calls the
  /// web door; cancelling ends the call.
  Stream<List<SensedLevel>> recent(int n) => webDoor
      .recent(n)
      .map(
        (levels) => [for (final level in levels) (sensor: _none, level: level)],
      );

  /// A sensor nothing is of yet.
  static const Sensor _none = (segment: '', label: '', unit: '');
}
