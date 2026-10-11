import 'dart:async';

import 'package:sensor_core/src/services/session_settings.dart';
import 'package:zenoh_dart/zenoh.dart';

/// Starts zenoh's own log, printed to standard output: for a program with a
/// terminal. [level] applies unless `RUST_LOG` is set. Once per process,
/// before any session opens.
void initZenohLogging(String level) => Zenoh.initLog(level);

/// Zenoh's own log at [level] as lines, for a program with no terminal to
/// print to, such as an app. Once per process, before any session opens, and
/// never after [initZenohLogging].
Stream<String> zenohLog(String level) =>
    Zenoh.initLogWithSink(minSeverity: LogSeverity.values.byName(level))
        .map((record) => 'zenoh ${record.severity.name}: ${record.message}');

/// A declared publisher on one key expression, as the service hands it out:
/// text in, marked `text/plain` on every put.
class Publication {
  new _(this._publisher);

  final Publisher _publisher;

  /// Puts [text] on the publication's key expression, marked `text/plain`.
  void put(String text) => _publisher.put(text, encoding: Encoding.textPlain);

  /// Undeclares the publisher. Safe to call twice.
  void close() => _publisher.close();
}

/// A sample as the service hands it up: the key expression it was put on, and
/// its payload as text.
typedef KeyedPayload = ({String keyExpr, String payload});

/// A queryable's error reply, as a get hands it up: the text it was answered
/// with.
class QueryError implements Exception {
  /// An error reply whose text is [message].
  new(this.message);

  /// The error reply's text.
  final String message;

  @override
  String toString() => 'QueryError: $message';
}

/// A sample as a subscription hands it up: the key expression it was put on,
/// its payload as text, and its time.
typedef TimedPayload = ({String keyExpr, String payload, DateTime time});

/// A declared subscriber on one key expression, as the service hands it out:
/// each sample as the key it was put on, its payload as text, and its time.
class Subscription {
  new _(this._subscriber);

  final Subscriber _subscriber;

  /// Every sample that arrives, with its key and its time, in order of
  /// arrival. The time is the sample's zenoh timestamp, stamped by its
  /// publisher's session when that session's configuration turns timestamping
  /// on; a sample without one has the time it arrived.
  Stream<TimedPayload> get samples => _subscriber.stream.map(
    (sample) => (
      keyExpr: sample.keyExpr,
      payload: sample.payload,
      time: switch (sample.timestamp) {
        final Timestamp stamp => _asTime(stamp),
        null => DateTime.now().toUtc(),
      },
    ),
  );

  /// A zenoh timestamp's time: NTP64 from the UNIX epoch, whole seconds in
  /// the top 32 bits and a binary fraction of a second in the bottom 32.
  static DateTime _asTime(Timestamp stamp) {
    final ntp64 = stamp.time;
    final seconds = ntp64 >>> 32;
    final fraction = ntp64 & 0xFFFFFFFF;
    return DateTime.fromMicrosecondsSinceEpoch(
      seconds * Duration.microsecondsPerSecond +
          (fraction * Duration.microsecondsPerSecond >> 32),
      isUtc: true,
    );
  }

  /// The payload of every sample that arrives, as text, in order of arrival.
  Stream<String> get payloads => samples.map((sample) => sample.payload);

  /// Undeclares the subscriber. Safe to call twice.
  void close() => _subscriber.close();
}

/// What a queryable answers a query with, given the query's selector
/// parameters: its replies, each a key expression and its text.
typedef QueryHandler = FutureOr<Iterable<KeyedPayload>> Function(
  Map<String, String> parameters,
);

/// A declared queryable on one key expression, as the service hands it out:
/// it answers each query with what its handler returns.
class Answerer {
  new _(this._queryable);

  final Queryable _queryable;

  /// Undeclares the queryable. Safe to call twice.
  void close() => _queryable.close();
}

/// The owner of the zenoh session. It hands upward only plain Dart values and
/// its own [Publication]s, [Subscription]s and [Answerer]s.
class ZenohService {
  /// A service for one role's [settings]. Nothing opens until [open].
  new(this.settings);

  /// Which side of the topology this session is on.
  final SessionSettings settings;

  Session? _session;
  final _publications = <Publication>[];
  final _subscriptions = <Subscription>[];
  final _answerers = <Answerer>[];

  /// Opens the session with the settings. For a peer, when this returns, each
  /// connection they ask for is made, or the wait set by `scouting/delay` has
  /// run out, and zenoh keeps retrying the connections not made yet. For a
  /// client, this throws a `ZenohException` when no router answers.
  Future<void> open() async {
    _session = await Session.open(config: _config());
  }

  /// The session's id: up to thirty-two hexadecimal characters.
  String get zid => _opened.zid.toHexString();

  /// The ids of the peers this session is connected to.
  List<String> get peerIds =>
      _opened.peersZid().map((id) => id.toHexString()).toList();

  /// Declares a publisher on [keyExpr]. The service closes it on [dispose].
  Publication declarePublication(String keyExpr) {
    final publication = Publication._(_opened.declarePublisher(keyExpr));
    _publications.add(publication);
    return publication;
  }

  /// Declares a subscriber on [keyExpr]. The service closes it on [dispose].
  Subscription declareSubscription(String keyExpr) {
    final subscription = Subscription._(_opened.declareSubscriber(keyExpr));
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Sends a query on [keyExpr] with the selector's [parameters], and hands up
  /// each reply as the key it was answered on and its text, every one of them
  /// in the order it arrives: no consolidation, where zenoh's default keeps
  /// only the latest reply on each key. The stream ends when every queryable
  /// has answered.
  Stream<KeyedPayload> get(
    String keyExpr, {
    Map<String, String> parameters = const {},
  }) => _opened
      .get(
        keyExpr,
        parameters: _asSelectorParameters(parameters),
        consolidation: ConsolidationMode.none,
      )
      .map((reply) => (keyExpr: reply.ok.keyExpr, payload: reply.ok.payload));

  /// Declares a queryable on [keyExpr] that answers each query with what
  /// [answer] returns for its parameters, then lets the query go, which tells
  /// the asker this queryable has finished. The service closes it on
  /// [dispose].
  Answerer declareQueryable(String keyExpr, QueryHandler answer) {
    final queryable = _opened.declareQueryable(keyExpr);
    queryable.stream.listen((query) async {
      for (final reply in await answer(_asParameterMap(query.parameters))) {
        query.reply(reply.keyExpr, reply.payload);
      }
      query.dispose();
    });
    final answerer = Answerer._(queryable);
    _answerers.add(answerer);
    return answerer;
  }

  /// Closes the publications, the subscriptions, the queryables and the
  /// session. Safe before [open], and more than once.
  void dispose() {
    for (final publication in _publications) {
      publication.close();
    }
    _publications.clear();
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions.clear();
    for (final answerer in _answerers) {
      answerer.close();
    }
    _answerers.clear();
    _session?.close();
    _session = null;
  }

  Config _config() => Config.fromStr(settings.json5);

  /// [parameters] as a selector writes them: `key=value`, joined by `;`.
  static String _asSelectorParameters(Map<String, String> parameters) =>
      parameters.entries.map((p) => '${p.key}=${p.value}').join(';');

  /// A selector's parameters, `key=value` joined by `;`, read back as a map.
  static Map<String, String> _asParameterMap(String text) => {
    for (final [key, ...value]
        in text
            .split(';')
            .where((pair) => pair.isNotEmpty)
            .map((pair) => pair.split('=')))
      key: value.join('='),
  };

  Session get _opened {
    final session = _session;
    if (session == null) {
      throw StateError('open() has not been called on this ZenohService');
    }
    return session;
  }
}
