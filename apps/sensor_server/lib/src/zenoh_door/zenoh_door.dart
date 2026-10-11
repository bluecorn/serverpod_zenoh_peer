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

  /// The key expression the door answers on: every sensor of the phone.
  static const keyExpr = 'archive/phone/**';

  /// Opens the door, reading the archive through [session]: a queryable that
  /// answers with the last `n` levels the selector asks for (none without a
  /// readable `n`), and a publication of each level kept, until the
  /// subscription it returns is cancelled. The service closes the queryable
  /// and the publications when it is disposed.
  StreamSubscription<SensorLevel> open(Session session) {
    zenoh.declareQueryable(keyExpr, (parameters) async {
      final n = int.tryParse(parameters['n'] ?? '') ?? 0;
      final levels = await archive.recent(session, n);
      return levels.map(_asPayload);
    });
    final publications = <String, Publication>{};
    return recorder.kept.listen((level) {
      final (:keyExpr, :payload) = _asPayload(level);
      (publications[keyExpr] ??= zenoh.declarePublication(
        keyExpr,
      )).put(payload);
    });
  }

  /// A level as the door hands it out: on its sensor's archive key, such as
  /// `archive/phone/accel`, as `<ISO-8601 time>,<level>`.
  static KeyedPayload _asPayload(SensorLevel level) => (
    keyExpr: level.keyExpr.replaceFirst('sensor/', 'archive/'),
    payload: '${level.time.toUtc().toIso8601String()},${level.level}',
  );
}
