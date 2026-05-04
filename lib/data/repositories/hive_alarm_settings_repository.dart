import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/alarm_settings.dart';
import 'alarm_settings_repository.dart';

/// Single-row Hive store for [AlarmSettings]. The whole settings record
/// lives under one well-known key so reads are O(1) and writes replace
/// atomically — the AlarmEngine listens via [watch] and re-reconciles on
/// every change.
class HiveAlarmSettingsRepository implements AlarmSettingsRepository {
  HiveAlarmSettingsRepository(this._box);

  static const String boxName = 'alarm_settings';
  static const String _key = 'singleton';

  final Box<AlarmSettings> _box;

  @override
  Future<AlarmSettings> read() async => _box.get(_key) ?? AlarmSettings.defaults;

  @override
  Future<void> write(AlarmSettings settings) => _box.put(_key, settings);

  @override
  Stream<AlarmSettings> watch() {
    // Same controller pattern as HiveShiftRepository.watchInRange — async*
    // over a broadcast box.watch() leaks subscriptions on cancel.
    late StreamController<AlarmSettings> controller;
    StreamSubscription<BoxEvent>? sub;
    var cancelled = false;

    Future<void> emit() async {
      if (cancelled || controller.isClosed) return;
      final value = _box.get(_key) ?? AlarmSettings.defaults;
      if (cancelled || controller.isClosed) return;
      controller.add(value);
    }

    controller = StreamController<AlarmSettings>(
      onListen: () async {
        await emit();
        if (cancelled) return;
        sub = _box.watch(key: _key).listen((_) => emit());
      },
      onCancel: () async {
        cancelled = true;
        await sub?.cancel();
      },
    );

    return controller.stream;
  }
}
