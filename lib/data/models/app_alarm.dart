import 'package:hive_ce/hive.dart';

import 'shift_type.dart';

part 'app_alarm.g.dart';

/// How an [AppAlarm] repeats. Display strings live in the UI layer
/// (`alarms_screen.dart`) — this enum is data-only.
///
/// The full semantics (which calendar dates each variant resolves to,
/// how `followsRotation` binds to a `ShiftCycle`) are intentionally
/// out of scope this phase. The "complex bundle logic" — actually
/// scheduling alarms from these rules — lands in the next phase. For
/// now the AlarmsScreen reads, displays, and toggles `enabled`, and
/// nothing downstream consumes [AppAlarm]; the engine still operates
/// on per-shift alarms derived from the shift box.
@HiveType(typeId: 5)
enum AppAlarmRepeatType {
  @HiveField(0)
  followsRotation,
  @HiveField(1)
  oneTime,
}

/// User-defined alarm rule. Separate from the per-shift alarms the
/// engine schedules — this is the durable "I want a 06:00 wake-up"
/// concept, eventually bound to a `ShiftCycle` (via `followsRotation`)
/// or a single date (via `oneTime`).
///
/// Lifetime: created on the AlarmsScreen, edited via toggle / future
/// edit flow, deleted via swipe-or-button. Persisted in the `alarms`
/// Hive box keyed by [id].
@HiveType(typeId: 6)
class AppAlarm {
  AppAlarm({
    required this.id,
    required this.minutesOfDay,
    required this.label,
    required this.repeatType,
    this.enabled = true,
    this.linkedShiftType,
    this.isRelativeTime = false,
    this.relativeOffsetMinutes = 90,
  })  : assert(
          minutesOfDay >= 0 && minutesOfDay < 1440,
          'minutesOfDay must be 0..1439',
        ),
        assert(
          relativeOffsetMinutes > 0,
          'relativeOffsetMinutes must be positive — a zero/negative offset '
          'would fire at or after the shift starts, defeating the purpose',
        );

  @HiveField(0)
  final String id;

  /// Minute-of-day for the alarm to ring (0..1439). Same shape that
  /// `Shift.startMinutes` uses, so existing format helpers
  /// (`formatHhmm`) work without conversion.
  @HiveField(1)
  final int minutesOfDay;

  /// Free-text label, e.g. "Wake Up - Day Shift". User-editable.
  @HiveField(2)
  final String label;

  @HiveField(3)
  final AppAlarmRepeatType repeatType;

  /// Toggled by the Switch on each card in `AlarmsScreen`. When false
  /// `AlarmSyncService` skips this alarm during its desired-set
  /// computation, and the next sync cancels any pending OS notifications
  /// for it.
  @HiveField(4)
  final bool enabled;

  /// Which shift type this alarm rings before. Only meaningful when
  /// `repeatType == followsRotation` — `oneTime` alarms ignore it.
  /// `null` for one-time alarms AND for legacy records (no migration
  /// needed; the field's absence reads back as null).
  ///
  /// `AlarmSyncService` filters the next 30 days of shifts by this
  /// type and emits one OS alarm per matching shift at the alarm's
  /// `minutesOfDay` on that shift's date.
  @HiveField(5)
  final ShiftType? linkedShiftType;

  /// "Time before shift" mode for follows-rotation alarms.
  ///
  ///   * `false` (default, exact-time): the OS alarm fires at
  ///     `shift.date + minutesOfDay`. This is the simple "wake me up
  ///     at 06:00 on every Day shift" case.
  ///   * `true` (relative): the OS alarm fires at
  ///     `shift.startDateTime - relativeOffsetMinutes`. Lets the user
  ///     say "wake me up 90 minutes before any Day shift starts"
  ///     without manually re-computing the alarm time for every
  ///     shift-start variation across a custom roster.
  ///
  /// Ignored for `oneTime` alarms (those are inherently exact).
  /// `false` is the default so the simpler mental model is the path
  /// of least resistance; existing records pre-dating this field read
  /// back as `false` via the adapter's `defaultValue`.
  @HiveField(6, defaultValue: false)
  final bool isRelativeTime;

  /// Minutes before `shift.startDateTime` to fire when [isRelativeTime]
  /// is `true`. Default 90 (1h 30m) — a typical "shower, eat, commute"
  /// runway for a Day-shift worker. Existing records pre-dating this
  /// field read back as 90 via the adapter's `defaultValue`.
  @HiveField(7, defaultValue: 90)
  final int relativeOffsetMinutes;

  /// `clearLinkedShiftType: true` lets a caller swap a `followsRotation`
  /// alarm back to `oneTime` without leaving a stale `linkedShiftType`
  /// behind — without it, passing `linkedShiftType: null` in copyWith
  /// would be indistinguishable from "leave unchanged".
  AppAlarm copyWith({
    String? id,
    int? minutesOfDay,
    String? label,
    AppAlarmRepeatType? repeatType,
    bool? enabled,
    ShiftType? linkedShiftType,
    bool clearLinkedShiftType = false,
    bool? isRelativeTime,
    int? relativeOffsetMinutes,
  }) =>
      AppAlarm(
        id: id ?? this.id,
        minutesOfDay: minutesOfDay ?? this.minutesOfDay,
        label: label ?? this.label,
        repeatType: repeatType ?? this.repeatType,
        enabled: enabled ?? this.enabled,
        linkedShiftType: clearLinkedShiftType
            ? null
            : (linkedShiftType ?? this.linkedShiftType),
        isRelativeTime: isRelativeTime ?? this.isRelativeTime,
        relativeOffsetMinutes:
            relativeOffsetMinutes ?? this.relativeOffsetMinutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAlarm &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          minutesOfDay == other.minutesOfDay &&
          label == other.label &&
          repeatType == other.repeatType &&
          enabled == other.enabled &&
          linkedShiftType == other.linkedShiftType &&
          isRelativeTime == other.isRelativeTime &&
          relativeOffsetMinutes == other.relativeOffsetMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        minutesOfDay,
        label,
        repeatType,
        enabled,
        linkedShiftType,
        isRelativeTime,
        relativeOffsetMinutes,
      );

  @override
  String toString() =>
      'AppAlarm(id: $id, time: $minutesOfDay, label: "$label", '
      'repeat: $repeatType, enabled: $enabled, '
      'linkedShiftType: $linkedShiftType, '
      'isRelativeTime: $isRelativeTime, '
      'relativeOffsetMinutes: $relativeOffsetMinutes)';
}
