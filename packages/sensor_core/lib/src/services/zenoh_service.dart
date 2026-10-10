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

/// A declared subscriber on one key expression, as the service hands it out:
/// each sample as the key it was put on and its payload as text.
class Subscription {
  new _(this._subscriber);

  final Subscriber _subscriber;

  /// Every sample that arrives, with its key, in order of arrival.
  Stream<KeyedPayload> get samples => _subscriber.stream.map(
    (sample) => (keyExpr: sample.keyExpr, payload: sample.payload),
  );

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
  new _();

  /// Undeclares the queryable.
  void close() {}
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
  /// each reply as the key it was answered on and its text. The stream ends
  /// when every queryable has answered.
  Stream<KeyedPayload> get(
    String keyExpr, {
    Map<String, String> parameters = const {},
  }) => const Stream.empty();

  /// Declares a queryable on [keyExpr] that answers each query with what
  /// [answer] returns for its parameters.
  Answerer declareQueryable(String keyExpr, QueryHandler answer) =>
      Answerer._();

  /// Closes the publications, the subscriptions and the session. Safe before
  /// [open], and more than once.
  void dispose() {
    for (final publication in _publications) {
      publication.close();
    }
    _publications.clear();
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions.clear();
    _session?.close();
    _session = null;
  }

  Config _config() => Config.fromStr(settings.json5);

  Session get _opened {
    final session = _session;
    if (session == null) {
      throw StateError('open() has not been called on this ZenohService');
    }
    return session;
  }
}
