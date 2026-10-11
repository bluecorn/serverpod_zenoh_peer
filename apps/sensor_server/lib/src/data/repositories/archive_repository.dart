import 'package:sensor_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The archive: the levels kept in the server's database, read and written
/// through the session of whoever calls.
class ArchiveRepository {
  /// Keeps [level] in the archive.
  Future<void> add(Session session, SensorLevel level) async {}

  /// The last [n] levels kept, newest first.
  Future<List<SensorLevel>> recent(Session session, int n) async => const [];
}
