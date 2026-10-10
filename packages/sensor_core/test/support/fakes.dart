import 'dart:async';

import 'package:sensor_core/sensor_core.dart';

class FakeSensorService implements SensorService {
  new(this.readings, {this._gyroscope = const Stream.empty()});

  final Stream<Reading> readings;
  final Stream<Reading> _gyroscope;

  @override
  Stream<Reading> accelerometer() => readings;

  @override
  Stream<Reading> gyroscope() => _gyroscope;
}

class FakePublication implements Publication {
  new(this.keyExpr);

  final String keyExpr;
  final puts = <String>[];
  bool isClosed = false;

  @override
  void put(String text) => puts.add(text);

  @override
  void close() => isClosed = true;
}

class FakeSubscription implements Subscription {
  new(this.keyExpr);

  final String keyExpr;
  final arrivals = StreamController<KeyedPayload>();
  bool isClosed = false;

  @override
  Stream<KeyedPayload> get samples => arrivals.stream;

  @override
  Stream<String> get payloads => samples.map((sample) => sample.payload);

  @override
  void close() => isClosed = true;
}

class FakeZenohService implements ZenohService {
  final publications = <FakePublication>[];
  final subscriptions = <FakeSubscription>[];

  @override
  Publication declarePublication(String keyExpr) {
    final publication = FakePublication(keyExpr);
    publications.add(publication);
    return publication;
  }

  @override
  Subscription declareSubscription(String keyExpr) {
    final subscription = FakeSubscription(keyExpr);
    subscriptions.add(subscription);
    return subscription;
  }

  final gets = <({String keyExpr, Map<String, String> parameters})>[];
  List<KeyedPayload> replies = [];

  @override
  Stream<KeyedPayload> get(
    String keyExpr, {
    Map<String, String> parameters = const {},
  }) {
    gets.add((keyExpr: keyExpr, parameters: parameters));
    return Stream.fromIterable(replies);
  }

  @override
  Answerer declareQueryable(String keyExpr, QueryHandler answer) =>
      throw UnimplementedError();

  @override
  SessionSettings get settings => const SessionSettings('{}');

  @override
  Future<void> open() async {}

  @override
  String get zid => 'a-fake';

  @override
  List<String> get peerIds => const [];

  @override
  void dispose() {}
}
