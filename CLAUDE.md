# CLAUDE.md — serverpod_zenoh_bridge

## What this is

**Serverpod as a native zenoh peer**: a bridge between a zenoh network of devices and the Dart and Flutter application
tier, built for *Build Something Real*, the Serverpod hackathon (submissions close 2026-10-14, 23:59 CEST). A phone
publishes sensor readings over zenoh; a Serverpod server, itself a zenoh peer, streams them to browsers through
Serverpod's endpoints, **the web door**, turns them into a per-second vibration level kept in an archive, and answers
native apps' zenoh queries on it, **the zenoh door**. It extends
[`zenoh_sensors`](https://github.com/bluecorn/zenoh_sensors), the project of the guide
[zenoh in Dart and Flutter](https://github.com/bluecorn/zenoh-dart-flutter-guide), whose history it starts from.

## The mandate

> **The mandate: KISS, a tracer bullet.** You are building part of a skeleton that extends `zenoh_sensors`: the minimal,
> well-structured, tested application that serves as a template for other applications. It is a tracer bullet: a thin,
> real path through every layer, kept and grown later. Every layer is present in its thinnest real form; anything that
> is not a layer's thinnest instance is left out and named, not built. Reuse `sensor_core`, `sensor_node` and the
> server before adding a package or an app. Write each test before its code, follow the architecture and the method
> below, add no layer they do not name, and stop to ask rather than widen the scope.

**The tracer bullet**, each layer once:

| layer | its thinnest real form |
|---|---|
| device | `apps/sensor_node`, node role, on Android: the accelerometer and gyroscope, asked for every 20 ms (a hint: Android may deliver faster); each sensor's readings numbered from 1 each time the node starts, and put as `n,x,y,z` |
| network | zenoh peers introduced by `zenohd` (gossip); the emulator joins as a client while developing |
| server | `apps/sensor_server` (Serverpod 4.0.4): a zenoh subscription on `sensor/phone/*`; each reading streamed to the web door, and a vibration level per key per second for the archive (the RMS of the acceleration's magnitude around its mean), computed from whatever was stamped in that second, by the readings' zenoh timestamps |
| archive | one SQLite table (time, key, level), time-indexed |
| web door | the endpoints `readings()` (a stream of every reading) and `recent(n)`; `apps/sensor_web`, a Flutter web app with the phone's own screen (each key's latest reading, the time it was stamped, the phone's number for it and how many reached the page), plus its last *n* levels |
| zenoh door | the server's zenoh queryable on `archive/phone/**`, answering the last *n* levels (n in total, newest first), each on `archive/phone/<sensor>` as `<ISO-8601 time>,<level>`; and each level published on the same key as it is kept: history by query, live by subscription |
| native view | `sensor_node` in the **monitor role**, on Linux: the same view model and screen over a zenoh subscription, plus a recent-levels panel fed by the zenoh door |

**Named, not built:** health indicators, retention, paging, thresholds and alerts, charts, authentication, commands,
several nodes, the monitor on Android, zenoh's advanced publisher and subscriber for history and live in one (unstable,
behind `zenoh_unstable.dart`), a deterministic wire rate (the node thinning its own stream), a UI package
shared by the three views (the page copies the phone's screen, since `sensor_core` brings `zenoh_dart` into a web
build), a silent sensor's last second (it is closed only by the sensor's next reading), the server's own log of a
failed archive read (the error goes to the asker, as zenoh's error reply), the shared domain model (`Reading` and
`Level` moved into `sensor_domain` and carried by Serverpod's models: dart_mappable or Freezed classes as extra
classes, a Serverpod shared package, or records), a codec that carries readings and levels as `ZBytes` in zenoh's
own serialization, sensors that describe themselves on the wire, the node's number as a zenoh attachment beside the
payload, telling one run of the node from another (its zenoh session id).

## The architecture

MVVM, the same layering in every app; everything below the view model is plain Dart.

```
sensor_node   View → ViewModel → readingsProvider → SensorNodeRepository → SensorService (sensors_plus)   node role
                                                                         → ZenohService → zenoh_dart
                                                 → ReadingsRepository → ZenohService                     monitor role
sensor_server Endpoints (web door) and a zenoh queryable (zenoh door) → the server's providers → repositories
              → ZenohService, and the archive (a Serverpod table)
sensor_web    View → ViewModel → repository → the generated Serverpod client
sensor_core   the shared core: domain models (Reading, Level, and RawReading, what the device delivers),
              repositories, ZenohService; it re-exports sensor_domain
sensor_domain the domain every program shares, plain Dart with no dependency, so the page can import it: Sensor,
              a record of a key's last segment, a label and a unit, and sensorOf
```

1. **Riverpod 3, providers declared by hand, no code generation for them.** The provider graph is the dependency
   injection: services, repositories and reads are declared in each app's `lib/config/providers.dart`, and tests
   replace entries with overrides.
2. **A repository becomes an interface when a test needs a fake of it**, not before.
3. **View models are `Notifier`s or `AsyncNotifier`s**; loading and errors travel as `AsyncValue`. **Views are
   `ConsumerWidget`s** watching one view model each. View models catch `on Object`.
4. **Folders:** `lib/config/`, `lib/data/{services,repositories}/`, `lib/domain/`, `lib/ui/<feature>/` (screen and view
   model side by side); `test/` mirrors `lib/`. `very_good_analysis` in every package, no suppressions in hand-written
   code.
5. **`ZenohService` is the only file in `lib/` that imports `package:zenoh_dart`**, and hands only plain Dart upward.
   The repository owns the key expressions. The service is disposed through its provider, and `dispose()` is safe twice.
6. **Tests use hand-written fakes** in `test/support/fakes.dart`, faking only the layer directly below; no mocking
   framework.

**Deviations, and why.** *The server's providers live in one `ProviderContainer`, held at the top level:* Serverpod
builds endpoints with no constructor arguments and its test tools never call `run()`, so `run()` fills the holder for
real and a test fills it with overrides. *Serverpod owns SIGINT and SIGTERM* and exits after its shutdown tasks, so the
zenoh session is closed in a shutdown task (`pod.experimental.shutdownTasks`, an experimental API), not in a `finally`.

## The method: test-driven, claim first

Each stage of the work states its claim before any code, and the tests are limited to what that claim needs.

1. **The claim first.** A stage opens with its **flow test**: one sentence about the system as its name, written against
   skeletons that answer with neutral values, run **red on an assertion**, committed before any production code.
2. **The map is the budget.** A doc comment above the flow test lists its expectations and the inner test that makes
   each true. **No inner test that is not on the map**, unless it names the expectation that needs it or is a contract
   test, labelled as one.
3. **Cycles of one test.** Red on an assertion; the smallest change to green, its move named (fake it, triangulate, or
   the obvious implementation); then **the refactor assessment**: refactor only when the structure needs it, otherwise
   "nothing to change". Commits in that order: `test:` (red), `feat:` (green, the move named), `refactor:` when there
   is one. Never squashed.
4. **Two passes.** The data side first, middle-out (`sensor_core`, the server's data layers); then each app outside in,
   from its view down to the providers.
5. **Three kinds of test.** Flow (one per stage, real zenoh), layer (one layer, faking the one below), contract (a rule
   of the pattern; one representative per rule, grouped at the end, labelled). Real zenoh only in flow tests and
   `ZenohService`'s own tests: two sessions in one process, on the loopback.
6. **Every test survives three checks.** *Stub:* the dumbest code that passes must not be plausible by accident.
   *Sentence:* its name is one sentence about the system, not about an object's shape. *Break:* name what you would
   break to make it fail; if only deleting the method does, it proves existence, not behaviour.
7. **Rejected as a test's only assertion:** `isA<…>`, `returnsNormally`, `isNotNull`, "returns a list", "is
   consistent", output that echoes the input. No tests of `zenoh_dart`'s or Serverpod's own behaviour, only of ours.
8. **A new test goes at the end of its file;** a test whose claim changes is a new test at the end, and the old one goes.
9. **The review gate.** Work written by an agent is merged only after its tests are run again, each passes the three
   checks, and its history shows each `test:` commit before its `feat:`.

## Running it

Every command from the **workspace root**, every Dart and Flutter command through [fvm](https://fvm.app)
(`.fvmrc`: Flutter 3.47.5, Dart 3.13.4). `zenohd` 1.8.0 or newer runs first, on the laptop.

```sh
fvm flutter pub get
fvm dart test packages/sensor_core
fvm dart run apps/sensor_server/bin/main.dart --apply-migrations   # the server; never from inside apps/sensor_server
```

- **Why the root.** `zenoh_dart` 1.0.0-rc.1 looks for its native library in `.dart_tool/lib/` under the working
  directory, and the build hook stages it at the workspace root. From inside `apps/sensor_server`, `dart run`,
  `dart test` and `serverpod start` all fail with `Could not find libzenoh_dart.so` (run 2026-10-10). The server finds
  its own folder from `Platform.script` and passes it to Serverpod as `serverDirectory`; its tests pass
  `serverDirectory` to `withServerpod`.
- **Code generation** after changing an endpoint or a model, inside `apps/sensor_server`:
  `fvm dart pub global run serverpod_cli:serverpod_cli generate` (the CLI activated with
  `fvm dart pub global activate serverpod_cli 4.0.4`; its `serverpod` launcher runs whatever `dart` is on `PATH`).
  After changing a table model, `… serverpod_cli create-migration` in the same folder; the migrations are committed.
- **The database** is SQLite, `apps/sensor_server/server.db` (not committed); the tests make their own per group.
  The workspace root depends on the server as on the core, so that `dart test` and `dart run` from the root build
  and map SQLite's native libraries as well as zenoh's.
- **The web app** is built into the server's `web/app`:
  `cd apps/sensor_web && fvm flutter build web --base-href / --output ../sensor_server/web/app`.

## Facts that bind the work

- **The sampling period is a hint.** Android's documentation: *"This is only a hint to the system. Events may be
  received faster or slower than the specified rate. Usually events are received faster."* Nothing may depend on the
  delivered rate.
- **A reading's time is its zenoh timestamp,** which a session stamps on what it publishes only when its configuration
  says `timestamping: { enabled: true }` (each of `sensor_node`'s files does; a router stamps by default). A reading
  without one takes the time it arrived, so the setting can be turned off; no test asserts it.
- **zenoh peers form a clique and pass nothing along;** a router in its default mode carries nothing between two
  peers, only introduces them (gossip). A router does carry data for its clients. Each pair of peers needs one side
  listening where the other can reach it: the phone listens on its port 7447, the server on the laptop's loopback.
- **An Android app off screen loses its network** within about five to eight seconds: the node keeps the screen on,
  and the node and the monitor never share one phone.
- **Serverpod's `--no-database` scaffold** still adds cloud storage with a database fallback, and leaves
  `features: database: false` to be set by hand.

## Working rules

- **Commits:** each completed cycle is committed without asking, in the order above. **Pushes only on Hugo's word**,
  at a stage's end, after he has seen it run. Stage explicit paths.
- **Agents:** every agent's prompt opens with the mandate and the method above, verbatim; its work comes back through
  the review gate.
- **Names:** only public projects are named in this repository.
