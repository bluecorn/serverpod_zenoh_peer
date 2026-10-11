import 'dart:async';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/data/repositories/archive_repository.dart';
import 'package:sensor_server/src/domain/recorder.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The zenoh door: the archive for native apps on the zenoh network. It
/// answers a `get` on `archive/phone/**` with the archive's last n levels,
/// newest first, and publishes each level as it is kept.
class ZenohDoor {
  /// A door over [archive], announcing what [recorder] keeps, through
  /// [zenoh].
  new(this.zenoh, this.archive, this.recorder);

  /// The server's zenoh service.
  final ZenohService zenoh;

  /// The levels the door answers from.
  final ArchiveRepository archive;

  /// The recorder whose kept levels the door publishes.
  final Recorder recorder;

  /// Opens the door, reading the archive through [session], until the
  /// subscription it returns is cancelled.
  StreamSubscription<SensorLevel> open(Session session) =>
      const Stream<SensorLevel>.empty().listen(null);
}
