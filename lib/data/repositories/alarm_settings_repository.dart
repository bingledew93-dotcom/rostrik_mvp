import '../models/alarm_settings.dart';

/// Persistence contract for [AlarmSettings]. The concrete Hive-backed impl
/// will live alongside the existing storage repos and is wired into
/// `LocalStorage` later — for now the AlarmEngine only depends on this
/// interface so it can be tested with an in-memory fake.
abstract class AlarmSettingsRepository {
  /// Returns the persisted settings, or [AlarmSettings.defaults] if none
  /// have been written yet.
  Future<AlarmSettings> read();

  Future<void> write(AlarmSettings settings);

  /// Emits the current settings then a new value on every write.
  Stream<AlarmSettings> watch();
}
