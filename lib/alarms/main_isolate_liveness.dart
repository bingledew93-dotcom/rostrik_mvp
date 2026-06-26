import 'dart:isolate';
import 'dart:ui';

/// Main-isolate liveness beacon.
///
/// The background-sync isolate must NOT open/mutate Hive while the main UI
/// isolate is alive in the same process (iOS can fire a background task while
/// the app is merely suspended) — concurrent opens race the id-map monotonic
/// counter and the `_scheduledFireAt` persistence across two in-memory caches.
/// The main isolate registers a port under [alarmActionPortName]; the bg isolate
/// checks for it via [mainIsolateIsAlive] and bails if present.
///
/// (This was historically owned by `NotificationActionDispatcher` — which also
/// listened on the port for FLN background action messages. With FLN removed the
/// listener is dead; only the liveness beacon survives, extracted here so the
/// dispatcher and the rest of the FLN stack can be deleted.)
///
/// `IsolateNameServer` here is `dart:ui`'s static, platform-backed registry.
/// This file deliberately imports NO `hive_ce` (which shadows it with an
/// instance-based one), so the unprefixed reference resolves correctly — the
/// same registry the background isolate queries.
const String alarmActionPortName = 'alarm_action_port';

/// Held for the process lifetime so the registered SendPort stays valid and the
/// ReceivePort is never garbage-collected. Intentionally NOT listened to — the
/// port exists only as a presence beacon now that FLN's action sender is gone.
ReceivePort? _livenessPort;

/// Registers the main-isolate liveness beacon. Call once from `main()`. Removes
/// any stale mapping first so a dev hot-restart re-registers cleanly.
void registerMainIsolatePort() {
  _livenessPort?.close(); // hot-restart: release the previous beacon first
  IsolateNameServer.removePortNameMapping(alarmActionPortName);
  final port = ReceivePort();
  final ok = IsolateNameServer.registerPortWithName(
    port.sendPort,
    alarmActionPortName,
  );
  if (!ok) {
    port.close();
    _livenessPort = null;
    return;
  }
  _livenessPort = port;
}

/// True when the main UI isolate is alive in THIS process (the beacon is
/// registered). The background sync bails when this is true to avoid racing
/// Hive. On Android boot the UI isolate is dead, the lookup is null, and the
/// background reconcile proceeds.
bool mainIsolateIsAlive() =>
    IsolateNameServer.lookupPortByName(alarmActionPortName) != null;
