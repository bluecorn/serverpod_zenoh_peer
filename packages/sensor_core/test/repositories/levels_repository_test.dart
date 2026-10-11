import 'package:sensor_core/sensor_core.dart';
import 'package:test/test.dart';

import '../support/collector.dart';
import '../support/fakes.dart';
import '../support/settings.dart';

void main() {
  /// The flow test of the zenoh door's asking side. The answering side is a
  /// test double, a queryable declared through the service that holds four
  /// levels newest first and answers with as many as `n` asks for. So the
  /// order and the cap are the double's; what the claim checks of our code is
  /// that `n` reaches the answerer and that every reply comes back, in order,
  /// parsed into a level under its key.
  ///
  /// The map, each expectation and the inner test that makes it true:
  ///
  /// 1. The reader sends its query on `archive/phone/**` with `n` as a
  ///    selector parameter: "the reader of the node sim asks archive/sim/**
  ///    for its last n levels" (`levels_repository_test.dart`, a fake
  ///    service).
  /// 2. Each reply's text, `<time>,<level>`, is parsed into a level under its
  ///    key, in the order received: "replies time,value arrive as levels
  ///    under their keys, in order" (`levels_repository_test.dart`, a fake
  ///    service).
  /// 3. A queryable answers a query with the replies its handler returns,
  ///    each with its key and text: "a queryable answers a get with the keys
  ///    and texts its handler returns" (`zenoh_service_test.dart`, a plain
  ///    session asking).
  /// 4. A query hands up each reply with the key it was answered on and its
  ///    text: "a get receives each reply with its key and its text"
  ///    (`zenoh_service_test.dart`).
  /// 5. Every reply arrives, several on one key included, in the order it
  ///    was sent: "every reply to a get arrives, several on one key, in the
  ///    order sent" (`zenoh_service_test.dart`).
  /// 6. The query's parameters reach the queryable's handler, so `n` does:
  ///    "the parameters of a get reach the handler of the queryable"
  ///    (`zenoh_service_test.dart`).
  ///
  /// And one contract test, at the end of `zenoh_service_test.dart`:
  /// "disposing the service lets its isolate exit, with a queryable
  /// declared", the rule that dispose closes what the service declared.
  test("a reader's get on archive/phone/** receives, from a queryable, the "
      'levels it holds, newest first, at most n', () async {
    // The archive's end: its session, from the settings that listen, and a
    // double of the archive: a queryable holding four levels newest first,
    // answering with as many as n asks for.
    final archiveNode = ZenohService(sensorNodeSettings());
    addTearDown(archiveNode.dispose);
    await archiveNode.open();
    const held = [
      (
        keyExpr: 'archive/phone/accel',
        payload: '2026-10-10T12:00:04.000Z,0.183',
      ),
      (
        keyExpr: 'archive/phone/gyro',
        payload: '2026-10-10T12:00:03.000Z,0.021',
      ),
      (
        keyExpr: 'archive/phone/accel',
        payload: '2026-10-10T12:00:02.000Z,0.150',
      ),
      (
        keyExpr: 'archive/phone/gyro',
        payload: '2026-10-10T12:00:01.000Z,0.019',
      ),
    ];
    archiveNode.declareQueryable(
      'archive/phone/**',
      (parameters) => held.take(int.parse(parameters['n']!)),
    );

    // The reader's end: a session from the settings that connect.
    final readerNode = ZenohService(collectorSettings());
    addTearDown(readerNode.dispose);
    await readerNode.open();
    // The declaration travels to the reader, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The code to implement: a repository that asks for the last three
    // levels of the phone.
    final repository = LevelsRepository(readerNode, nodeName: 'phone');
    final levels = await repository.recent(3);

    // The claim: the three newest levels, newest first, each under its key,
    // with the time and the value it left with.
    final answered = levels
        .map((l) => [l.keyExpr, l.level.time, l.level.value])
        .toList();
    expect(answered, [
      ['archive/phone/accel', DateTime.utc(2026, 10, 10, 12, 0, 4), 0.183],
      ['archive/phone/gyro', DateTime.utc(2026, 10, 10, 12, 0, 3), 0.021],
      ['archive/phone/accel', DateTime.utc(2026, 10, 10, 12, 0, 2), 0.150],
    ]);
  });

  test(
    'the reader of the node sim asks archive/sim/** for its last n levels',
    () async {
      // A fake: a service that records the queries sent through it.
      final zenoh = FakeZenohService();

      // The code to implement: one query, on the expression built from the
      // node's name, carrying n as a selector parameter.
      final repository = LevelsRepository(zenoh, nodeName: 'sim');
      await repository.recent(5);

      // The claim: one query on every key of the sim node's archive, asking
      // for five levels.
      final sent = zenoh.gets.map((g) => [g.keyExpr, g.parameters]).toList();
      expect(sent, [
        [
          'archive/sim/**',
          {'n': '5'},
        ],
      ]);
    },
  );

  test(
    'replies time,value arrive as levels under their keys, in order',
    () async {
      // A fake: a service whose query answers with two replies, as the
      // archive's queryable sends them.
      final zenoh = FakeZenohService()
        ..replies = [
          (
            keyExpr: 'archive/phone/gyro',
            payload: '2026-10-10T12:00:02.000Z,0.021',
          ),
          (
            keyExpr: 'archive/phone/accel',
            payload: '2026-10-10T12:00:01.000Z,0.183',
          ),
        ];
      final repository = LevelsRepository(zenoh, nodeName: 'phone');

      // The code to implement: each reply's text parsed into a level, handed
      // on with the key it was answered on.
      final levels = await repository.recent(2);

      // The claim: two levels, in the order of the replies, each under its key
      // with the time and the value of its text.
      final answered = levels
          .map((l) => [l.keyExpr, l.level.time, l.level.value])
          .toList();
      expect(answered, [
        ['archive/phone/gyro', DateTime.utc(2026, 10, 10, 12, 0, 2), 0.021],
        ['archive/phone/accel', DateTime.utc(2026, 10, 10, 12, 0, 1), 0.183],
      ]);
    },
  );

  test('the levels reader of the node sim listens on archive/sim/*', () async {
    // A fake: a service that records what is declared on it.
    final zenoh = FakeZenohService();

    // The code to implement: listening to the live levels declares one
    // subscription, on the expression built from the node's name.
    final repository = LevelsRepository(zenoh, nodeName: 'sim');
    final listening = repository.live().listen((_) {});
    addTearDown(listening.cancel);

    // The claim: one subscription, on the expression that matches each of the
    // sim node's keys in the archive.
    final keys = zenoh.subscriptions.map((s) => s.keyExpr).toList();
    expect(keys, ['archive/sim/*']);
  });
}
