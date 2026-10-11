import 'dart:async';
import 'dart:isolate';

import 'package:sensor_core/sensor_core.dart';
import 'package:test/test.dart';
import 'package:zenoh_dart/zenoh.dart';

import '../support/collector.dart';
import '../support/settings.dart';

void main() {
  test('a sensor node and a collector find each other on loopback', () async {
    // The two ends: the sensor node, which listens, and a collector,
    // which connects to it. Each closes when the test ends.
    final sensorNode = ZenohService(sensorNodeSettings());
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(sensorNode.dispose);
    addTearDown(collectorNode.dispose);

    // The code to implement: two sessions opened from the files' text.
    // The sensor node opens first, so the collector has something to reach.
    await sensorNode.open();
    await collectorNode.open();

    // The claim: each one's peers hold the other's id, and the two ids differ.
    expect(collectorNode.peerIds, contains(sensorNode.zid));
    expect(sensorNode.peerIds, contains(collectorNode.zid));
    expect(collectorNode.zid, isNot(sensorNode.zid));
  });

  test('a service has an id once it is open', () async {
    // The sensor node's end, closed when the test ends.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);

    // The code to implement: an id, once the service is open.
    await sensorNode.open();

    // The claim: the id is not empty.
    expect(sensorNode.zid, isNotEmpty);
  });

  test('two services have different ids', () async {
    // Two ends, closed when the test ends.
    final sensorNode = ZenohService(sensorNodeSettings());
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(sensorNode.dispose);
    addTearDown(collectorNode.dispose);

    // The code to implement: each open service gets its own id.
    await sensorNode.open();
    await collectorNode.open();

    // The claim: the two ids differ.
    expect(collectorNode.zid, isNot(sensorNode.zid));
  });

  test('neither side announces itself on the network', () {
    // The code to implement: both sides' files, each parsed by zenoh and read
    // back as data. An absence cannot be watched, so it is checked as the
    // value behind it.
    final sensorConfig = Config.fromStr(sensorNodeSettings().json5);
    final collectorConfig = Config.fromStr(collectorSettings().json5);
    addTearDown(sensorConfig.dispose);
    addTearDown(collectorConfig.dispose);

    // The claim: both sides are peers that neither scout nor gossip.
    for (final config in [sensorConfig, collectorConfig]) {
      expect(config.get('mode'), '"peer"');
      expect(config.get('scouting/multicast/enabled'), 'false');
      expect(config.get('scouting/gossip/enabled'), 'false');
    }
  });

  test('the collector connects to where the sensor node listens', () {
    // The code to implement: the endpoints of both files, each parsed by
    // zenoh and read back as data.
    const address = '["tcp/127.0.0.1:7451"]';
    final sensorConfig = Config.fromStr(sensorNodeSettings().json5);
    final collectorConfig = Config.fromStr(collectorSettings().json5);
    addTearDown(sensorConfig.dispose);
    addTearDown(collectorConfig.dispose);

    // The claim: the sensor node listens at the address and connects to
    // nothing, and the collector listens nowhere and connects to it.
    expect(sensorConfig.get('listen/endpoints'), address);
    expect(sensorConfig.get('connect/endpoints'), '[]');
    expect(collectorConfig.get('listen/endpoints'), '[]');
    expect(collectorConfig.get('connect/endpoints'), address);
  });

  test('a collector opens even when no sensor node is listening', () async {
    // A collector alone: nothing listens at its address.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);

    await collectorNode.open();

    // The claim: the session opens, with no peers.
    expect(collectorNode.peerIds, isEmpty);
  });

  test('disposing is safe before open, and more than once after', () async {
    // A rule of the pattern: disposing never throws, whatever the state.
    final sensorNode = ZenohService(sensorNodeSettings());
    expect(sensorNode.dispose, returnsNormally);

    await sensorNode.open();
    sensorNode.dispose();

    // The claim: a second dispose after open is safe too.
    expect(sensorNode.dispose, returnsNormally);
  });

  test('asking an unopened service for its id is an error', () {
    // A rule of the pattern: an unopened service has no id to give.
    final sensorNode = ZenohService(sensorNodeSettings());

    // The claim: asking throws a StateError.
    expect(() => sensorNode.zid, throwsStateError);
  });

  test('a put through a publication reaches a subscriber as text', () async {
    // The node's end: its session, from the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The laptop's end: a plain session that subscribes, as z_sub does.
    final collector = await openCollector();
    addTearDown(collector.close);
    final subscriber = collector.declareSubscriber('sensor/phone/accel');
    addTearDown(subscriber.close);
    final received = <Sample>[];
    subscriber.stream.listen(received.add);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The new contract to implement: declare a publication on a key,
    // then put text through it.
    sensorNode
        .declarePublication('sensor/phone/accel')
        .put('0.000,9.776,0.812');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the text arrives, marked text/plain.
    final payloads = received.map((sample) => sample.payload).toList();
    expect(payloads, ['0.000,9.776,0.812']);
    expect(received.single.encoding, 'text/plain');
  });

  test(
    'a subscriber that arrives after a put sees only what follows',
    () async {
      // The node's end: a session and its publication.
      final sensorNode = ZenohService(sensorNodeSettings());
      addTearDown(sensorNode.dispose);
      await sensorNode.open();
      final publication = sensorNode.declarePublication('sensor/phone/accel');

      // The laptop's end: a plain session, with no subscriber yet.
      final collector = await openCollector();
      addTearDown(collector.close);

      // A put before anyone subscribes, given time to cross before the
      // subscriber exists.
      publication.put('before');
      await Future<void>.delayed(delivery);

      // Subscribe late. Wait once for the declaration to reach the node's
      // side, and once for the next put to arrive.
      final subscriber = collector.declareSubscriber('sensor/phone/accel');
      addTearDown(subscriber.close);
      final received = <Sample>[];
      subscriber.stream.listen(received.add);
      await Future<void>.delayed(delivery);
      publication.put('after');
      await Future<void>.delayed(delivery);

      // The claim: pub/sub keeps nothing, so only the later put arrives.
      final payloads = received.map((sample) => sample.payload).toList();
      expect(payloads, ['after']);
    },
  );

  test('disposing the service closes its publications', () async {
    // A rule of the pattern: dispose closes what the service declared.
    final sensorNode = ZenohService(sensorNodeSettings());
    await sensorNode.open();
    final publication = sensorNode.declarePublication('sensor/phone/accel');

    sensorNode.dispose();

    // The claim: a put after dispose is an error, because the publisher
    // underneath is closed.
    expect(() => publication.put('late'), throwsStateError);
  });

  test('closing a publication twice is safe', () async {
    // A rule of the pattern, which the repository's cancel and the
    // service's dispose both rely on.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();
    final publication = sensorNode.declarePublication('sensor/phone/accel')
      ..close();

    // The claim: the second close returns normally.
    expect(publication.close, returnsNormally);
  });

  test('a subscription receives the text a publication puts', () async {
    // The node's end: its session, from the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The new contract to implement: declare a subscription on a key, then
    // collect the text that arrives through it.
    final subscription = collectorNode.declareSubscription(
      'sensor/phone/accel',
    );
    final received = <String>[];
    subscription.payloads.listen(received.add);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The node puts text through a publication.
    sensorNode
        .declarePublication('sensor/phone/accel')
        .put('0.000,9.776,0.812');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the same text arrives.
    expect(received, ['0.000,9.776,0.812']);
  });

  test('disposing the service closes its subscriptions', () async {
    // A rule of the pattern: dispose closes what the service declared.
    final collectorNode = ZenohService(collectorSettings());
    await collectorNode.open();
    final subscription = collectorNode.declareSubscription(
      'sensor/phone/accel',
    );

    collectorNode.dispose();

    // The claim: the subscription's stream ends, because the subscriber
    // underneath is closed.
    expect(subscription.payloads, emitsDone);
  });

  test('closing a subscription twice is safe', () async {
    // A rule of the pattern, which the repository's cancel and the
    // service's dispose both rely on.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();
    final subscription = collectorNode.declareSubscription('sensor/phone/accel')
      ..close();

    // The claim: the second close returns normally.
    expect(subscription.close, returnsNormally);
  });

  test('a sample arrives with the key it was put on', () async {
    // The node's end: its session, from the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The new contract to implement: the samples a subscription hands up,
    // each the key it was put on and its payload as text.
    final subscription = collectorNode.declareSubscription(
      'sensor/phone/accel',
    );
    final received = <KeyedPayload>[];
    subscription.samples.listen(
      (sample) =>
          received.add((keyExpr: sample.keyExpr, payload: sample.payload)),
    );
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The node puts text through a publication on that key.
    sensorNode
        .declarePublication('sensor/phone/accel')
        .put('0.000,9.776,0.812');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the sample arrives with the key it was put on.
    expect(received, [
      (keyExpr: 'sensor/phone/accel', payload: '0.000,9.776,0.812'),
    ]);
  });

  test('a subscriber to sensor/phone/* receives the key of the put', () async {
    // The node's end: its session, from the settings that listen.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The code to implement: the key of each sample read from the sample.
    // The subscription's own expression names a set of keys.
    final subscription = collectorNode.declareSubscription('sensor/phone/*');
    final received = <KeyedPayload>[];
    subscription.samples.listen(
      (sample) =>
          received.add((keyExpr: sample.keyExpr, payload: sample.payload)),
    );
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The node puts text on one key of that set.
    sensorNode.declarePublication('sensor/phone/gyro').put('0.000,0.000,0.500');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the sample arrives with the key of the put, not with the
    // subscription's expression.
    expect(received, [
      (keyExpr: 'sensor/phone/gyro', payload: '0.000,0.000,0.500'),
    ]);
  });

  test('a wildcard stands for one segment of a key', () async {
    // A pin about zenoh: what a subscription on sensor/phone/* leaves out.
    final sensorNode = ZenohService(sensorNodeSettings());
    addTearDown(sensorNode.dispose);
    await sensorNode.open();
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();
    final subscription = collectorNode.declareSubscription('sensor/phone/*');
    final received = <String>[];
    subscription.samples.listen((sample) => received.add(sample.keyExpr));
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The node puts on a key of three segments, and on one of four.
    sensorNode.declarePublication('sensor/phone/gyro').put('in');
    sensorNode.declarePublication('sensor/phone/gyro/raw').put('too deep');
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: only the key of three segments arrives.
    expect(received, ['sensor/phone/gyro']);
  });

  test(
    'a queryable answers a get with the keys and texts its handler returns',
    () async {
      // The archive's end: its session, from the settings that listen.
      final archiveNode = ZenohService(sensorNodeSettings());
      addTearDown(archiveNode.dispose);
      await archiveNode.open();

      // The new contract to implement: declare a queryable whose handler
      // answers every query with two replies, each a key and its text.
      archiveNode.declareQueryable(
        'archive/phone/**',
        (_) => const [
          (
            keyExpr: 'archive/phone/accel',
            payload: '2026-10-10T12:00:01.000Z,0.183',
          ),
          (
            keyExpr: 'archive/phone/gyro',
            payload: '2026-10-10T12:00:01.000Z,0.021',
          ),
        ],
      );

      // The reader's end: a plain session that asks, as z_get does.
      final reader = await openCollector();
      addTearDown(reader.close);
      // The declaration travels to the reader, so give it time to arrive.
      // The witness asks with no consolidation, so it sees every reply as it
      // was sent.
      await Future<void>.delayed(delivery);
      final replies = await reader
          .get('archive/phone/**', consolidation: ConsolidationMode.none)
          .toList();

      // The claim: each reply arrives with the key and the text the handler
      // gave it.
      final answered = replies
          .map((r) => (keyExpr: r.ok.keyExpr, payload: r.ok.payload))
          .toList();
      expect(answered, [
        (
          keyExpr: 'archive/phone/accel',
          payload: '2026-10-10T12:00:01.000Z,0.183',
        ),
        (
          keyExpr: 'archive/phone/gyro',
          payload: '2026-10-10T12:00:01.000Z,0.021',
        ),
      ]);
    },
  );

  test(
    'every reply to a get arrives, several on one key, in the order sent',
    () async {
      // The archive's end: a queryable that answers with four replies, three of
      // them on one key, as the archive answers with a sensor's last levels.
      final archiveNode = ZenohService(sensorNodeSettings());
      addTearDown(archiveNode.dispose);
      await archiveNode.open();
      archiveNode.declareQueryable(
        'archive/phone/**',
        (_) => const [
          (keyExpr: 'archive/phone/accel', payload: 'third'),
          (keyExpr: 'archive/phone/accel', payload: 'second'),
          (keyExpr: 'archive/phone/gyro', payload: 'only'),
          (keyExpr: 'archive/phone/accel', payload: 'first'),
        ],
      );

      // The reader's end: a session from the settings that connect.
      final readerNode = ZenohService(collectorSettings());
      addTearDown(readerNode.dispose);
      await readerNode.open();
      // The declaration travels to the reader, so give it time to arrive.
      await Future<void>.delayed(delivery);

      // The code to implement: a query that keeps every reply as it comes, not
      // one per key.
      final replies = await readerNode.get('archive/phone/**').toList();

      // The claim: the four replies, in the order the queryable sent them.
      final texts = replies.map((r) => '${r.keyExpr} ${r.payload}').toList();
      expect(texts, [
        'archive/phone/accel third',
        'archive/phone/accel second',
        'archive/phone/gyro only',
        'archive/phone/accel first',
      ]);
    },
  );

  test('the parameters of a get reach the handler of the queryable', () async {
    // The archive's end: a queryable whose handler keeps the parameters of
    // each query, and answers with nothing.
    final archiveNode = ZenohService(sensorNodeSettings());
    addTearDown(archiveNode.dispose);
    await archiveNode.open();
    final asked = <Map<String, String>>[];
    archiveNode.declareQueryable('archive/phone/**', (parameters) {
      asked.add(parameters);
      return const [];
    });

    // The reader's end: a session from the settings that connect.
    final readerNode = ZenohService(collectorSettings());
    addTearDown(readerNode.dispose);
    await readerNode.open();
    // The declaration travels to the reader, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The code to implement: the parameters written into the query's
    // selector, and read back out of it on the answering side.
    await readerNode
        .get('archive/phone/**', parameters: {'n': '20', 'sensor': 'accel'})
        .drain<void>();

    // The claim: the handler is asked once, with both parameters.
    expect(asked, [
      {'n': '20', 'sensor': 'accel'},
    ]);
  });

  test(
    'disposing the service lets its isolate exit, with a queryable declared',
    () async {
      // A rule of the pattern: dispose closes what the service declared. A
      // queryable left open keeps its isolate alive after the session has
      // closed, so whether a program can end shows whether it was closed.
      final exited = ReceivePort();
      addTearDown(exited.close);

      // The code to implement: a service that, on dispose, closes the
      // queryable it declared, in a program of its own.
      final program = await Isolate.spawn(
        _declareAQueryableAndDispose,
        null,
        onExit: exited.sendPort,
      );
      addTearDown(() => program.kill(priority: Isolate.immediate));

      // The claim: the program ends once it has disposed its service.
      final ended = await exited.first
          .then((_) => true)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      expect(ended, isTrue, reason: 'still running 3 s after its dispose');
    },
  );

  test('a sample arrives with the time its publisher stamped it', () async {
    // The node's end: a plain session that listens, as z_pub is on the
    // laptop, which stamps its put with its own clock.
    final witness = await Session.open(
      config: Config.fromStr(sensorNodeSettings().json5),
    );
    addTearDown(witness.close);

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The code to implement: each sample handed up with its time.
    final subscription = collectorNode.declareSubscription('sensor/phone/*');
    final received = <TimedPayload>[];
    subscription.samples.listen(received.add);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The witness stamps a put, between two readings of the wall clock.
    final publisher = witness.declarePublisher('sensor/phone/accel');
    addTearDown(publisher.close);
    final before = DateTime.now();
    final stamp = witness.newTimestamp();
    final after = DateTime.now();
    publisher.put('0.000,9.776,0.812', timestamp: stamp);
    // A put returns before the sample arrives, so give it time to cross.
    await Future<void>.delayed(delivery);

    // The claim: the sample's time lies between the two readings of the
    // clock, which the time it arrived would not.
    final time = received.single.time;
    expect(
      time.difference(before).inMicroseconds,
      inInclusiveRange(0, after.difference(before).inMicroseconds),
    );
  });

  test('a sample that carries no timestamp arrives with the time it '
      'arrived', () async {
    // The node's end: a plain session that listens and stamps nothing, as a
    // session does when timestamping is off in its configuration.
    final witness = await Session.open(
      config: Config.fromStr(sensorNodeSettings().json5),
    );
    addTearDown(witness.close);

    // The laptop's end: a collector's session, from the settings that
    // connect.
    final collectorNode = ZenohService(collectorSettings());
    addTearDown(collectorNode.dispose);
    await collectorNode.open();

    // The code to implement: a sample with no timestamp handed up with the
    // time it arrived.
    final subscription = collectorNode.declareSubscription('sensor/phone/*');
    final received = <TimedPayload>[];
    subscription.samples.listen(received.add);
    // The declaration travels to the node, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The witness puts with no timestamp; the sample arrives after the put
    // returns, and before the wait ends.
    final publisher = witness.declarePublisher('sensor/phone/accel');
    addTearDown(publisher.close);
    publisher.put('0.000,9.776,0.812');
    final sent = DateTime.now();
    await Future<void>.delayed(delivery);
    final waited = DateTime.now();

    // The claim: the sample's time lies between the put and the end of the
    // wait.
    final time = received.single.time;
    expect(
      time.difference(sent).inMicroseconds,
      inInclusiveRange(0, waited.difference(sent).inMicroseconds),
    );
  });

  test('a get to a queryable whose handler fails ends at once with the '
      "handler's error, which goes no further", () async {
    // The archive's end: a queryable whose handler fails, as the archive's
    // does when its database cannot be read. It is declared in a zone that
    // keeps every error escaping it: in the server, such an error ends the
    // program.
    final archiveNode = ZenohService(sensorNodeSettings());
    addTearDown(archiveNode.dispose);
    await archiveNode.open();
    final escaped = <Object>[];
    runZonedGuarded(
      () => archiveNode.declareQueryable(
        'archive/phone/**',
        (_) => throw StateError('the archive cannot be read'),
      ),
      (error, _) => escaped.add(error),
    );

    // The reader's end: a session from the settings that connect.
    final readerNode = ZenohService(collectorSettings());
    addTearDown(readerNode.dispose);
    await readerNode.open();
    // The declaration travels to the reader, so give it time to arrive.
    await Future<void>.delayed(delivery);

    // The code to implement: the handler's failure answered with zenoh's
    // error reply, the query let go, and the error reply handed up as an
    // error. The get is followed to its end, its errors kept on the way.
    final errors = <Object>[];
    final ended = await readerNode
        .get('archive/phone/**')
        .handleError(errors.add)
        .drain<void>()
        .then((_) => true)
        .timeout(const Duration(seconds: 2), onTimeout: () => false);

    // The claim: the get ends well before the asker's timeout of 10 s, having
    // handed up the handler's error, and nothing escapes the queryable.
    expect(ended, isTrue, reason: 'still waiting 2 s after the get');
    expect(errors, [
      isA<QueryError>().having(
        (error) => error.message,
        'message',
        contains('the archive cannot be read'),
      ),
    ]);
    expect(escaped, isEmpty);
  });
}

/// A program that opens a service, declares a queryable through it, and
/// disposes the service. Nothing else is left to keep it running.
Future<void> _declareAQueryableAndDispose(void _) async {
  final service = ZenohService(collectorSettings());
  await service.open();
  service
    ..declareQueryable('archive/phone/**', (_) => const [])
    ..dispose();
}
