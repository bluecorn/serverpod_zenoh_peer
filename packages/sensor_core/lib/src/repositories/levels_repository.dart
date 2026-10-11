import 'dart:async';

import 'package:sensor_core/src/domain/level.dart';
import 'package:sensor_core/src/services/zenoh_service.dart';

/// The asking side of the archive: it owns the key expressions and turns the
/// replies to a query, and the levels the archive publishes, back into levels.
class LevelsRepository {
  /// A repository asking, through [zenoh], for the archived levels of every
  /// sensor of the node called [nodeName], and receiving the ones the archive
  /// publishes.
  new(this.zenoh, {required String nodeName})
    : keyExpr = 'archive/$nodeName/**',
      liveKeyExpr = 'archive/$nodeName/*';

  /// The service the query and the subscription go through.
  final ZenohService zenoh;

  /// The key expression the query is sent on: it matches each of the node's
  /// keys in the archive.
  final String keyExpr;

  /// The key expression the live levels' subscription is declared on: one
  /// segment for the sensor, so it matches each of the node's keys.
  final String liveKeyExpr;

  /// The last [n] levels the archive answers with, each parsed from
  /// `<ISO-8601 time>,<level>` and handed on with the key it was answered on,
  /// in the order the archive answers.
  Future<List<KeyedLevel>> recent(int n) => zenoh
      .get(keyExpr, parameters: {'n': '$n'})
      .map((reply) => (keyExpr: reply.keyExpr, level: _asLevel(reply.payload)))
      .toList();

  /// Every level the archive publishes as it keeps it, parsed as [recent]'s
  /// replies are and handed on with the key it was put on. Listening declares
  /// the subscription; cancelling closes it.
  Stream<KeyedLevel> live() {
    late final Subscription subscription;
    late final StreamSubscription<TimedPayload> listening;
    final controller = StreamController<KeyedLevel>();
    controller.onListen = () {
      subscription = zenoh.declareSubscription(liveKeyExpr);
      listening = subscription.samples.listen(
        (sample) => controller.add((
          keyExpr: sample.keyExpr,
          level: _asLevel(sample.payload),
        )),
      );
    };
    controller.onCancel = () async {
      await listening.cancel();
      subscription.close();
    };
    return controller.stream;
  }

  static Level _asLevel(String text) {
    final [time, value] = text.split(',');
    return Level(time: DateTime.parse(time), value: double.parse(value));
  }
}
