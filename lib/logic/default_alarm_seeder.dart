import 'package:uuid/uuid.dart';

import '../data/models/app_alarm.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/app_alarm_repository.dart';

/// Creates one enabled follows-rotation wake-up alarm per distinct working
/// shift type in [workTypes], each using the global lead time (a null per-alarm
/// offset). This is what onboarding's "Automate My Alarms" arms: a brand-new
/// user lands on the Dashboard already covered for every shift type their
/// rotation contains — zero manual alarm setup.
///
/// Rules:
///   * OFF is never armed (it has no shift to ring before) — only Day,
///     Afternoon and Night are considered, in that fixed display order.
///   * A type that already has a follows-rotation alarm is skipped, so the
///     call is idempotent and can never produce duplicates (e.g. if onboarding
///     somehow re-ran, or the user pre-seeded alarms another way).
///
/// Returns the alarms it actually created (empty when everything was already
/// covered). Pure orchestration over the repository — no Flutter, no Hive — so
/// it unit-tests directly against a fake repo, keeping the alarm-arming policy
/// out of the widget layer.
Future<List<AppAlarm>> seedDefaultAlarms({
  required AppAlarmRepository alarms,
  required Iterable<ShiftType> workTypes,
  Uuid uuid = const Uuid(),
}) async {
  final wanted = workTypes.toSet();
  final existing = await alarms.getAll();
  final alreadyCovered = existing
      .where((a) => a.repeatType == AppAlarmRepeatType.followsRotation)
      .map((a) => a.linkedShiftType)
      .whereType<ShiftType>()
      .toSet();

  final created = <AppAlarm>[];
  for (final type in const [
    ShiftType.day,
    ShiftType.afternoon,
    ShiftType.night,
  ]) {
    if (!wanted.contains(type)) continue;
    if (alreadyCovered.contains(type)) continue;
    final alarm = AppAlarm(
      id: uuid.v4(),
      // minutesOfDay is irrelevant for followsRotation (it fires at
      // shiftStart − lead), but the model requires a valid 0..1439 value.
      minutesOfDay: 6 * 60,
      label: '${defaultAlarmLabelFor(type)} wake-up',
      repeatType: AppAlarmRepeatType.followsRotation,
      enabled: true,
      linkedShiftType: type,
      // null → use the global AlarmSettings.leadTime (the primary default).
      relativeOffsetMinutes: null,
    );
    await alarms.upsert(alarm);
    created.add(alarm);
  }
  return created;
}

/// Human label for a seeded alarm's shift type. Exposed so the Arm Engine
/// screen can describe what it's about to arm ("Day & Night wake-up alarms")
/// using the same wording the seeder stamps on the records.
String defaultAlarmLabelFor(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return 'Day';
    case ShiftType.afternoon:
      return 'Afternoon';
    case ShiftType.night:
      return 'Night';
    case ShiftType.off:
      return 'Shift';
  }
}
