# serverpod_zenoh_bridge

**Serverpod as a native zenoh peer.** Robots and IoT devices increasingly talk over [zenoh](https://zenoh.io), and
Serverpod has no device transport of its own. This project puts a Serverpod server *on* the zenoh network, as a peer,
so a Dart and Flutter team can have one language from the device to the server to the browser. It is a skeleton
application, in Dart and Flutter, with every layer present in its thinnest real form and tested, meant as a template
for building applications on zenoh and Serverpod.

[Zenoh](https://zenoh.io), an Eclipse project, is a pub/sub/query protocol that unifies data in motion, data at rest
and computation, from the microcontroller to the data centre. Its site names the fields it serves: robotics, as a
next-generation middleware in place of DDS, ROS 2 included (`rmw_zenoh`); autonomous vehicles and automotive, from
V2X to software-defined vehicles; and IoT and edge computing. [ZettaScale](https://zettascale.tech), which offers it
commercially, adds case studies in agriculture, industry and transportation.

> Built for *Build Something Real*, the Serverpod hackathon (submissions close 14 October 2026). Everything described
> below is built and runs, but for what the applications map marks as opened, not built.

## What it shows

A phone strapped to a machine publishes its accelerometer and gyroscope over zenoh. The server, a zenoh peer, streams
the readings to browsers, turns them into a vibration level per second, keeps the levels, answers zenoh queries on
them, and publishes each one as it is kept:

```
                                        ┌──────────────────────────────────────────────┐
                                        │ zenohd   a router, on the laptop: it         │
                                        │   introduces the peers to one another,       │
                                        │   then carries none of their data            │
                                        └──────────────────────────────────────────────┘

 the phone                              the laptop
┌─────────────────────────────┐         ┌────────────────────────────────────────────────────────────────────────────┐
│ sensor_node   node role     │readings │ sensor_server   Serverpod, and a zenoh peer                                │
│   a zenoh peer              │════════►│   zenoh in:    subscribed to sensor/phone/*                                │
│   put on sensor/phone/accel │         │                └─► a level per sensor per second ──► the archive (SQLite)  │
│   put on sensor/phone/gyro  │ levels  │   zenoh out:   queryable on archive/phone/**: the last n levels            │
│   History tab: a get on     │◄════════│                each level, as it is kept, put on archive/phone/<sensor>    │
│   archive/phone/**?n=20,    │         │   Serverpod out, for clients without zenoh:                                │
│   then subscribed to        │         │                readings(): every reading, live                             │
│   archive/phone/*           │         │                recent(n): the last n levels, again each time one is kept   │
└───────╥─────────────────────┘         │   API server :8080                         web server :8082                │
        ║                               └────╥────────────┬──────────────────────────────────────┬───────────────────┘
        ║                                    ║            │                                      │
        ║ live readings,                     ║            │ WebSocket: readings(),               │ HTTP: the page
        ║ straight from                      ║            │ recent(20)                           │
        ║ the phone                          ║            │                                      │
        ║              zenoh: a get, a reply ║            │                                      │
        ║              per level; then each  ║            │                                      │
        ║              level as it is kept   ║            │                                      │
        ║                                    ║            │                                      │
        ║                                    ║       ┌────▼──────────────────────────────────────▼───────────────────┐
┌───────╨───────────────────────────────┐    ║       │ a browser: sensor_web   Flutter web                           │
│ sensor_node   monitor role, on Linux  │◄═══╝       │   the generated client, no zenoh                              │
│   a zenoh peer                        │            │   readings() for the live cards                               │
│   subscribed to sensor/phone/*        │            │   recent(20) for the levels cards                             │
│   get on archive/phone/**?n=20        │            └───────────────────────────────────────────────────────────────┘
│   subscribed to archive/phone/*       │
└───────────────────────────────────────┘
```

Double lines are zenoh, single lines Serverpod's WebSocket and HTTP. `zenohd` introduces the peers to one another and
carries none of their data; each pair then links directly. On the emulator, while developing, the node is a client of
`zenohd` instead, and the router carries its readings.

- **The web door:** browsers, which cannot join a zenoh network, reach the data through Serverpod's endpoints.
- **The zenoh door:** native apps on the network ask the server for the levels it keeps with a zenoh query, and follow
  each new one by subscribing to its key.
- **One app, two roles:** the monitor is the same Flutter app as the node, with the same view models and cards in a
  window of its own, reading instead of publishing. The phone's History tab asks the zenoh door too.

### The two doors

The monitor never addresses the server: it names keys, and zenoh brings the phone's readings straight from the phone.
The server answers only what it alone holds, the archive:

```
sensor_node (the phone)       sensor_server                     sensor_node, monitor role (Linux)
        │                           │                                           │
        │                           │ at start: subscribe sensor/phone/*        │
        │                           │           queryable archive/phone/**      │
        │                           │                                           │ at start: subscribe sensor/phone/*
        │                           │                                           │           subscribe archive/phone/*
        │                           │                                           │
        │                           │◄─── get archive/phone/**?n=20 ────────────┤ the levels cards ask for the levels
        │                           ├──── a reply per level, newest first ─────►│
        │                           ├──── done ────────────────────────────────►│ the get completes
        │                           │                                           │
        ├─ get archive/phone/** ───►│                                           │ the phone's History tab asks the
        │◄──── a reply per level ───┤                                           │ same when first opened, then
        │                           │                                           │ subscribes to archive/phone/*
        │                           │                                           │
        ├─ put sensor/phone/accel ─►│                                           │
        │ as n,x,y,z                │                                           │
        │                           │ into this second's level                  │
        ├───────────────────────────┼──────────────────────────────────────────►│ the same reading: show it with the
        │                           │                                           │ phone's number; count + 1
        │                           │                                           │
        │                           │ a second ends: keep its level             │
        │◄──────────────────────────┼──── put archive/phone/accel ─────────────►│ the levels cards and the
        │                           │      as <time>,<level>                    │ phone's History tab show it
```

A browser cannot speak zenoh, so the server is on every path: the page itself, the live readings and the levels:

```
sensor_node (the phone)       sensor_server                                sensor_web (a browser)
        │                           │                                                 │
        │                           │◄─── HTTP GET :8082/ ────────────────────────────┤ open the page
        │                           ├──── index.html, main.dart.js (web/app) ────────►│ the app starts
        │                           │                                                 │
        │                           │◄─── WebSocket :8080, call readings() ───────────┤ the live cards
        │                           │ a zenoh subscription for this call              │
        │                           │◄─── call recent(20) ────────────────────────────┤ the levels cards
        │                           ├──── the last 20 levels ────────────────────────►│
        │                           │                                                 │
        ├─ put sensor/phone/accel ─►│                                                 │
        │ as n,x,y,z                │                                                 │
        │                           │ into this second's level                        │
        │                           ├──── a SensorReading ───────────────────────────►│ show it with the
        │                           │                                                 │ phone's number;
        │                           │                                                 │ count + 1
        │                           │                                                 │
        │                           │ a second ends: keep its level                   │
        │                           ├──── the last 20 levels again ──────────────────►│ the levels cards show it
        │                           │                                                 │
        │                           │◄─── the streams are cancelled ──────────────────┤ the tab closes
        │                           │ that call's subscription closes; the            │
        │                           │ recorder's stays, it feeds the archive          │
```

| | the zenoh door: the monitor | the web door: a browser |
|---|---|---|
| speaks | zenoh, as a peer | Serverpod's protocol, HTTP and a WebSocket |
| addresses | keys: `sensor/phone/*`, `archive/phone/**` | the server: its URL, and the methods `readings()` and `recent(n)` |
| live readings | straight from the phone; the server is not on the path | from the server, which subscribes to the phone for each browser |
| the levels | a query for the last *n*, then each new one as the server publishes it | `recent(n)`: the last *n*, then again each time one is kept |
| if the server stops | the live readings go on; the levels stop | the page stops |

## What it opens

The bridge is shown on one application. The same two halves, zenoh between the devices and Serverpod on the server,
fit others. Each row says what zenoh does, what Serverpod does, and how much of it this project shows.

| application | zenoh's part | Serverpod's part | in this project |
|---|---|---|---|
| **Machine vibration monitoring**: a sensor on a machine, its vibration kept per second, watched from a desk and a browser | the device publishes; the server, a peer, subscribes, answers queries on the archive and publishes each level | a streaming endpoint for each browser; the archive, an ORM table with its migration; the page, served by the web server | **shown** |
| **Fleet monitoring**: many devices, one dashboard | each device on keys of its own, `sensor/<device>/*` (the repositories already take the device's name); one subscription, `sensor/*/*`, for all | the same endpoints and archive, keyed by device | **partly**: one device, `phone`; several are named, not built |
| **An edge server** beside the machines | the server a peer on the plant's own network, with no cloud on the path | one process on SQLite, as here | **partly**: on a laptop; an edge box not tried |
| **Commands to devices**: "start program 12", "go to the dock", not joystick rates | a put or a query from the server on a device's key | endpoints only signed-in users may call (`requireLogin`), each becoming a put or a query | **opened, not built** |
| **Scheduled work**: retention, nightly summaries, dispatch | queries to the devices on a schedule | future calls and recurring tasks (`callRecurring`) | **opened, not built** |
| **Alerts on thresholds** | a level published on a key of its own when it crosses one | the rule kept in a table, the alert streamed to the browsers | **opened, not built** |

**Where it stops.** Control loops and safety functions stay on the devices and on zenoh: a WebSocket over TCP and a
garbage-collected runtime promise no timing. The web door carries every reading to every browser, about a hundred a
second for each one at this demo's scale. Rates in the kilohertz, or many browsers, are where that ends, and the
levels are what scale. Device-to-device traffic is zenoh's, not the server's.

**What is not claimed.** An HTTP backend could already reach zenoh through zenoh's REST plugin. What is new here is
Serverpod as a zenoh peer in its own process, which `zenoh_dart` makes possible.

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

The page, *Sensor page*, shows a column for each sensor: its latest reading, the time the phone stamped it, the
phone's number for it and how many reached the page, above the last levels the archive kept. In a browser narrower
than 720 pixels the columns stack into one.

### 4. The monitor, on Linux

In a third terminal:

```sh
cd apps/sensor_node
fvm flutter build linux --dart-define=NODE_ROLE=monitor --dart-define=ZENOH_CONFIG=monitor
cd build/linux/x64/release/bundle
./sensor_node
```

Start it from its bundle folder, as here: from a folder with a `.dart_tool/lib/`, it would load that folder's zenoh
library instead of the one it was built with. Its window, *Sensor monitor*, shows a column for each sensor: the
phone's latest reading, read over zenoh, with the phone's number for it and how many arrived, above the last levels,
which it asks the server's zenoh door for and then follows as the server keeps them.

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

### Checking the readings from a terminal

`sensorctl`, the collector of the guide this project comes from, shows the phone's readings straight from zenoh,
without the server:

```sh
fvm dart run apps/sensorctl/bin/sensorctl.dart --config apps/sensorctl/config/router-peer.json5 watch
```

It prints each sensor's latest reading and how many have arrived. If it shows readings while the page stays empty, the
phone is publishing and the trouble is on the server's side; if it shows none, look at the phone and the router. Its
configuration is the monitor's: a peer that `zenohd` introduces. `Ctrl-C` stops it.

### Stopping, and the tests

`Ctrl-C` stops the router and the server, which closes its zenoh session on the way out; the monitor stops with its
window. The tests use loopback ports of their own, 7450 to 7452, so they run beside the router and the server:

```sh
fvm dart test packages/sensor_domain packages/sensor_core apps/sensor_server apps/sensorctl
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

## How it is built, and the part AI played

This project was built with Claude Code, running Claude Opus 5.5. Claude wrote the code, the tests and this
documentation. Every commit since the project was cloned from `zenoh_sensors` names Claude as co-author, and two of
them merge the work of Claude's subagents.

I decided what was built and how: the scope, the architecture and each design choice, settled question by question,
the first set of questions and answers in an interview run with the *grilling* skill from Matt Pocock's
[skills](https://github.com/mattpocock/skills) repository. I chose MVVM as the structure of each app. To keep Claude
and its subagents from over-engineering, I gave them one mandate: build a skeleton as a tracer bullet, through every
layer of the system, from the phone to the browser, each in its thinnest real form; leave anything more out, named
rather than built; and ask me rather than widen the scope. Each stage ran while I watched before it was pushed, on
the emulator, the Linux monitor or the browser, and the whole ran on my phone.

Test-driven development is what holds the assistant's code to what was asked for. The outer loop follows the
double-loop method of Freeman and Pryce: each stage opens with a flow test, its name one sentence about the system,
run against real zenoh sessions (the page's, which speaks no zenoh, against a fake of the web door) and committed
failing on an assertion before any code, and it stays red until the inner loops make it pass. The inner loops follow
Kent Beck's red, green, refactor, in the classic style: one test at a time, state asserted rather than calls,
hand-written fakes and no mocking framework, each step to green named as Beck names them (fake it, triangulate, the
obvious implementation), built middle-out on the data side and outside-in from each app's view. Refactoring is
assessed at every cycle and done only where the structure needs it. A comment above the flow test maps each of its
expectations to the inner test that makes it true, and that map is the test budget.

Done this way, the tests check the feature, not the code. An assistant that writes code and tests together tends to
test only the code's contract, that a method exists, returns something or does not throw, in tests that pass against a
stub that does nothing. Every test here must survive three checks against that: the dumbest code that passes it must
not be plausible, its name is a sentence about the system, and breaking the code it covers must fail it. A subagent's
work is merged only after its tests are run again and read against those checks. The history shows the order: each
`test:` commit before the `feat:` that makes it pass, never squashed. The rules are in [CLAUDE.md](CLAUDE.md).

`sensor_core` and `sensor_node` come from `zenoh_sensors`, built by following my guide *zenoh in Dart and Flutter*,
whose chapters were drafted with Claude Code too. No AI model or component is part of the project itself.

## Licence

Apache License 2.0 — see [LICENSE](LICENSE).
