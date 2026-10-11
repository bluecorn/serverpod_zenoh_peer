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

## Run it

Run on Linux x86_64, with the node on an Android emulator (an x86_64 image) and on a Pixel 9a over Wi-Fi.

**What you need:**
- [fvm](https://fvm.app), which installs the Flutter version this repository pins in `.fvmrc` (3.47.5, with Dart
  3.13.4). Every Dart and Flutter command below goes through it.
- Flutter's [Linux desktop](https://docs.flutter.dev/platform-integration/linux/setup) and
  [Android](https://docs.flutter.dev/platform-integration/android/setup) setups: the monitor is a Linux app, the node
  an Android app, run on an emulator or a phone.
- `zenohd`, zenoh's router, 1.8.0 or newer, from [zenoh's releases](https://github.com/eclipse-zenoh/zenoh/releases).
- No database server: the archive is a SQLite file the server creates.

**Every command runs from the repository's root** unless it says otherwise. `zenoh_dart` finds its native library
under the working directory's `.dart_tool/lib/`, where the build puts it; from inside `apps/sensor_server`, the server
fails with `Could not find libzenoh_dart.so`.

### 1. The code and the page

```sh
git clone https://github.com/bluecorn/serverpod_zenoh_bridge.git
cd serverpod_zenoh_bridge
fvm install
fvm flutter pub get
cd apps/sensor_web
fvm flutter build web --base-href / --output ../sensor_server/web/app
cd ../..
```

The page is a Flutter web app; the server serves its build.

### 2. The router, the server and the page

In a first terminal, the router, listening on the laptop's loopback:

```sh
zenohd --no-multicast-scouting -l tcp/127.0.0.1:7447
```

In a second, the server:

```sh
fvm dart run apps/sensor_server/bin/main.dart --apply-migrations
```

`--apply-migrations` creates the archive, `apps/sensor_server/server.db`, on the first run. Serverpod's warning that
its Insights server is disabled is expected. Open <http://localhost:8082/>.

### 3. The node, on the Android emulator

Start an emulator, then build the node with the configuration that makes it a client of the router (the emulator
reaches the laptop at `10.0.2.2`) and install it:

```sh
cd apps/sensor_node
fvm flutter build apk --debug --dart-define=ZENOH_CONFIG=emulator-client
adb install -r build/app/outputs/flutter-apk/app-debug.apk
cd ../..
```

Open `sensor_node` on the emulator. The emulator's sensors are still, so move them, from the emulator window's
Virtual sensors panel or with `adb`:

```sh
adb emu sensor set acceleration 2.5:9.8:1.0
adb emu sensor set gyroscope 0.8:0:0
```

The page shows each sensor's latest reading, the time the phone stamped it and the count, and beside them the last
levels the archive kept.

### 4. The monitor, on Linux

In a third terminal:

```sh
cd apps/sensor_node
fvm flutter build linux --dart-define=NODE_ROLE=monitor --dart-define=ZENOH_CONFIG=monitor
cd build/linux/x64/release/bundle
./sensor_node
```

Start it from its bundle folder, as here: from a folder with a `.dart_tool/lib/`, it would load that folder's zenoh
library instead of the one it was built with. Its window shows the phone's screen, read over zenoh, and a panel that
asks the server's zenoh door for the last levels, then follows each one the server keeps.

### With a real phone over Wi-Fi

The phone is a peer: it listens on its port 7447 and connects to the router on the laptop, which introduces it to the
server and the monitor; they connect to the phone directly.

1. Put the laptop and the phone on the same Wi-Fi network. A VPN on either can block the traffic between them: turn
   it off, or let local traffic through (with NordVPN, LAN Discovery, on both).
2. Make a copy of the phone's configuration, and in it replace `192.0.2.10` with the laptop's address on the Wi-Fi
   network (`ip -4 addr` shows it). Git ignores the copy.

   ```sh
   cp apps/sensor_node/config/router-peer.json5 apps/sensor_node/config/router-peer.local.json5
   ```

3. Start the router on that address and on the loopback, in place of the router of step 2:

   ```sh
   zenohd --no-multicast-scouting -l tcp/<the laptop's address>:7447 -l tcp/127.0.0.1:7447
   ```

   Name the two addresses rather than `0.0.0.0`: the phone announces every address it has, and two devices on the
   same VPN can share a tunnel address, so a connection meant for the phone could reach the laptop's own router.
4. Build the node with the copy and install it, over USB or wireless debugging:

   ```sh
   cd apps/sensor_node
   fvm flutter build apk --release --dart-define=ZENOH_CONFIG=router-peer.local
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   cd ../..
   ```

5. Open `sensor_node` on the phone and leave it on screen: Android cuts an app's network seconds after it leaves the
   screen, so the node keeps the screen on.

The server, the page and the monitor run as above.

### Stopping, and the tests

`Ctrl-C` stops the router and the server, which closes its zenoh session on the way out; the monitor stops with its
window. The tests run with the server stopped, since some listen on its port:

```sh
fvm dart test packages/sensor_core apps/sensor_server apps/sensorctl
fvm flutter test apps/sensor_node apps/sensor_web
```

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
