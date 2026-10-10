# serverpod_zenoh_bridge

**Serverpod as a native zenoh peer.** Robots and IoT devices increasingly talk over [zenoh](https://zenoh.io), and
Serverpod has no device transport of its own. This project puts a Serverpod server *on* the zenoh network, as a peer,
so a Dart and Flutter team can have one language from the device to the server to the browser.

> **Work in progress** for *Build Something Real*, the Serverpod hackathon (submissions close 14 October 2026). This
> README grows with the project; what is described below as planned is not built yet.

## What it shows

A phone strapped to a machine publishes its accelerometer and gyroscope over zenoh. The server, a zenoh peer, streams
the readings to browsers, turns them into a vibration level per second, keeps the levels, and answers zenoh queries on
them:

```
 the phone                              the laptop
 sensor_node ═══ zenoh (peers) ═══════► sensor_server   Serverpod, a zenoh peer
                                          ├─ a vibration level per sensor, per second ──► the archive (SQLite)
                                          ├─ the web door:   readings(), recent(n) ══════► sensor_web, in a browser
                                          └─ the zenoh door: a query on archive/phone/** ◄═ sensor_node, monitor role
 zenohd introduces the peers                                                                (Linux, native)
```

- **The web door:** browsers, which cannot join a zenoh network, reach the data through Serverpod's endpoints.
- **The zenoh door:** native apps on the network ask the server directly, with a zenoh query.
- **One app, two roles:** the monitor is the same Flutter app as the node, with the same view model and screen, reading
  instead of publishing.

## Where it comes from

It continues the EF IoT webinar of 17 June 2026, *Building a UI for Robotics Using Flutter and Zenoh*
([slides](https://github.com/bluecorn/flutter-zenoh-robotics-ui-webinar)), which put a Flutter UI on a robot's zenoh
network directly ([`flutter_zenoh_direct`](https://github.com/bluecorn/flutter_zenoh_direct)) instead of behind a
gateway node ([`flutter_zenoh_gateway`](https://github.com/bluecorn/flutter_zenoh_gateway)). This project puts the
server on that network too. It extends [`zenoh_sensors`](https://github.com/bluecorn/zenoh_sensors), the project of
the guide [zenoh in Dart and Flutter](https://github.com/bluecorn/zenoh-dart-flutter-guide), and its history starts
there; the server, the web app and the monitor are new. It uses [`zenoh_dart`](https://pub.dev/packages/zenoh_dart)
and [Serverpod](https://serverpod.dev) 4.

## How it is built

A tracer bullet: every layer once, in its thinnest real form, test-first, each feature starting from one claim stated
as a failing test, and its tests limited to what that claim needs. The rules are in [CLAUDE.md](CLAUDE.md). It is
built with Claude Code, Anthropic's coding assistant, under those rules; the full account comes with the submission.

## Licence

Apache License 2.0 — see [LICENSE](LICENSE).
