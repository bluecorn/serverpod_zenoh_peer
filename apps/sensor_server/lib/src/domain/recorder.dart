import 'dart:async';

import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/data/repositories/archive_repository.dart';
import 'package:sensor_server/src/domain/levels.dart';
import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Keeps each second's levels of the phone's readings in the archive, through
/// one subscription of its own, and tells its listeners each level it keeps.
class Recorder {
  /// A recorder of [readings] into [archive].
  new(this.readings, this.archive);

  /// The phone's readings.
  final ReadingsRepository readings;

  /// Where the levels are kept.
  final ArchiveRepository archive;

  final _kept = StreamController<SensorLevel>.broadcast();

  /// Each level, once it is kept.
  Stream<SensorLevel> get kept => _kept.stream;

  /// Starts keeping levels through [session], until the subscription it
  /// returns is cancelled.
  StreamSubscription<SensorLevel> start(Session session) =>
      levelsPerSecond(readings.readings())
          .asyncMap((level) async {
            await archive.add(session, level);
            return level;
          })
          .listen(_kept.add);

  /// Ends the stream of kept levels.
  Future<void> dispose() => _kept.close();
}
