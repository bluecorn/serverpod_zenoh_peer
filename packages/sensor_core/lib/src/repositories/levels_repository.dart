import 'package:sensor_core/src/domain/level.dart';
import 'package:sensor_core/src/services/zenoh_service.dart';

/// The asking side of the archive: it owns the key expression and turns the
/// replies to a query back into levels.
class LevelsRepository {
  /// A repository asking, through [zenoh], for the archived levels of every
  /// sensor of the node called [nodeName].
  new(this.zenoh, {required String nodeName})
    : keyExpr = 'archive/$nodeName/**';

  /// The service the query goes through.
  final ZenohService zenoh;

  /// The key expression the query is sent on: it matches each of the node's
  /// keys in the archive.
  final String keyExpr;

  /// The last [n] levels the archive answers with, each parsed from
  /// `<ISO-8601 time>,<level>` and handed on with the key it was answered on,
  /// in the order the archive answers.
  Future<List<KeyedLevel>> recent(int n) => zenoh
      .get(keyExpr, parameters: {'n': '$n'})
      .map((reply) => (keyExpr: reply.keyExpr, level: _asLevel(reply.payload)))
      .toList();

  static Level _asLevel(String text) {
    final [time, value] = text.split(',');
    return Level(time: DateTime.parse(time), value: double.parse(value));
  }
}
