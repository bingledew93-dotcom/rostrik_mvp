import 'package:hive_ce/hive.dart';

import '../../alarms/alarm_sound.dart';
import 'shift_type.dart';

part 'app_alarm.g.dart';

/// How an [AppAlarm] repeats. Display strings live in the UI layer
/// (`alarms_screen.dart`) — this enum is data-only.
///
///   * [followsRotation] — fires before every matching shift in the roster
///     (one OS alarm per shift inside the scheduling horizon). The lead time is
///     either the global [AlarmSettings.leadTime] or this alarm's
///     [AppAlarm.relativeOffsetMinutes] override.
///   * [weekly] — fires at the absolute [AppAlarm.minutesOfDay] on each ISO
///     weekday selected in [AppAlarm.weekdaysBitmask]. Independent of the
///     roster — a standard "every Mon/Wed/Fri at 06:30" recurring alarm. The
///     sync service materialises one OS alarm per due weekday inside the
///     scheduling horizon (the native background re-sync rolls the window
///     forward), so it has no native-repeat dependency and fires the same way
///     from a killed state as every other alarm.
///   * [oneTime] — fires once at the next future occurrence of
///     [AppAlarm.minutesOfDay].
///
/// `AlarmSyncService` is the live consumer of these rules; it reconciles them
/// into the OS pending set on every alarm / roster / settings change.
@HiveType(typeId: 5)
enum AppAlarmRepeatType {
  @HiveField(0)
  followsRotation,
  @HiveField(1)
  oneTime,
  @HiveField(2)
  weekly,
}

/// User-defined alarm rule, persisted in the `alarms` Hive box keyed by [id]
/// and consumed by `AlarmSyncService` to drive OS alarm scheduling.
///
/// Lifetime: created on the AlarmsScreen, edited via the create/edit sheet,
/// deleted via swipe-or-button.
///
/// **Lead-time model (followsRotation):** an alarm NEVER fires at an absolute
/// clock time — the whole point is that it tracks the shift start, so an exact
/// time that can't adapt when the shift moves is an anti-pattern. Instead the
/// fire time is `shiftStart − leadTime`, where `leadTime` is:
///   * the per-alarm [relativeOffsetMinutes] when it is set (an OVERRIDE), or
///   * the global [AlarmSettings.leadTime] when [relativeOffsetMinutes] is null
///     (the PRIMARY default — the single source of truth for standard alarms).
@HiveType(typeId: 6)
class AppAlarm {
  AppAlarm({
    required this.id,
    required this.minutesOfDay,
    required this.label,
    required this.repeatType,
    this.enabled = true,
    this.linkedShiftType,
    this.relativeOffsetMinutes,
    this.isCriticalShift = false,
    this.soundKey = kDefaultAlarmSoundKey,
    this.weekdaysBitmask = 0,
    this.autoDeleteAfterFiring = false,
  })  : assert(
          minutesOfDay >= 0 && minutesOfDay < 1440,
          'minutesOfDay must be 0..1439',
        ),
        assert(
          relativeOffsetMinutes == null || relativeOffsetMinutes > 0,
          'relativeOffsetMinutes, when set, must be positive — a zero/negative '
          'offset would fire at or after the shift starts, defeating the point',
        );

  @HiveField(0)
  final String id;

  /// Minute-of-day (0..1439). Only meaningful for [AppAlarmRepeatType.oneTime]
  /// — the absolute time it rings. Ignored for followsRotation alarms, which
  /// always fire relative to the shift start (see the class-level lead-time
  /// model). Kept the same shape as `Shift.startMinutes` so `formatHhmm` works.
  @HiveField(1)
  final int minutesOfDay;

  /// Free-text label, e.g. "Wake Up - Day Shift". User-editable.
  @HiveField(2)
  final String label;

  @HiveField(3)
  final AppAlarmRepeatType repeatType;

  /// Toggled by the Switch on each card in `AlarmsScreen`. When false
  /// `AlarmSyncService` skips this alarm during its desired-set computation,
  /// and the next sync cancels any pending OS notifications for it.
  @HiveField(4)
  final bool enabled;

  /// Which shift type a followsRotation alarm rings before. `null` for oneTime
  /// alarms (and legacy records — the field's absence reads back as null). A
  /// followsRotation alarm with a `null` link is invalid config and is skipped.
  @HiveField(5)
  final ShiftType? linkedShiftType;

  // HiveField(6) was `isRelativeTime` — removed in the lead-time rewire that
  // made followsRotation alarms always-relative. The field number is RETIRED,
  // not reused: any record still carrying field 6 is simply ignored on read.

  /// Per-alarm lead-time OVERRIDE for followsRotation alarms — minutes before
  /// the shift start to fire.
  ///
  ///   * `null` (default) → use the global [AlarmSettings.leadTime]. This is the
  ///     primary path; the global setting is the single source of truth for
  ///     standard shift alarms.
  ///   * a positive value → override the global lead time for THIS alarm only
  ///     (e.g. "wake me 90 min before Night shifts, but use the default for the
  ///     rest").
  ///
  /// Ignored for oneTime alarms. Legacy records that stored the old non-null
  /// default read back as that value — i.e. they become explicit overrides,
  /// which is the correct migration now that exact-time mode is gone.
  @HiveField(7)
  final int? relativeOffsetMinutes;

  /// "Critical shift" wake mechanics. When true the wake-up screen requires a
  /// sustained physical shake to dismiss, with a continuous 3-second hold as a
  /// fail-safe — a guard against a half-asleep swipe silencing a must-not-miss
  /// alarm. When false the normal slide-to-dismiss applies. Legacy records read
  /// back `false`.
  @HiveField(8, defaultValue: false)
  final bool isCriticalShift;

  /// Which bundled tone this alarm rings — an [AlarmSound.key] (e.g.
  /// `'classic'`, `'siren'`). The OS owns alarm audio, so this only selects
  /// which Android notification channel / iOS sound file the scheduler points
  /// the firing notification at; it never plays audio in-process.
  ///
  /// Defaults to [kDefaultAlarmSoundKey]. Legacy records (no field 9) read back
  /// the default via the adapter, and any unknown key resolves to the default
  /// at scheduling time (see [resolveAlarmSound]), so a tone removed in a
  /// future build can never strand an old alarm.
  @HiveField(9, defaultValue: kDefaultAlarmSoundKey)
  final String soundKey;

  /// Selected ISO weekdays for a [AppAlarmRepeatType.weekly] alarm, packed as a
  /// bitmask: bit `(weekday - 1)` set means that weekday is on
  /// (`DateTime.monday == 1` → bit 0 … `DateTime.sunday == 7` → bit 6). `0`
  /// means no day selected — the default, and what every legacy record (no
  /// field 10) reads back as, so non-weekly alarms simply ignore it. A scalar
  /// int (rather than a `List<int>`) keeps the Hive default trivially safe and
  /// matches the existing scalar-default convention on this class. Conversions
  /// to/from a `Set<int>` live in `lib/util/weekday_mask.dart`.
  @HiveField(10, defaultValue: 0)
  final int weekdaysBitmask;

  /// When true, the alarm record is permanently deleted from Hive the instant
  /// the user dismisses it — instead of lingering as a fired, stale config.
  /// Only meaningful for (and only ever set on) [AppAlarmRepeatType.oneTime]
  /// alarms; the create/edit sheet exposes the toggle for one-time only. The
  /// dismiss handlers (in-app wake screen, foreground dispatcher, killed-app
  /// background isolate) consult [shouldAutoDeleteOnDismiss] and delete via the
  /// `appAlarmId` carried in the notification payload. Legacy records (no field
  /// 11) read back `false`.
  @HiveField(11, defaultValue: false)
  final bool autoDeleteAfterFiring;

  /// `clearLinkedShiftType` / `clearRelativeOffset` let a caller reset a field
  /// back to `null` — without them, passing `null` is indistinguishable from
  /// "leave unchanged". `clearRelativeOffset` is how the create/edit sheet
  /// switches an alarm from a custom override back to the global default.
  AppAlarm copyWith({
    String? id,
    int? minutesOfDay,
    String? label,
    AppAlarmRepeatType? repeatType,
    bool? enabled,
    ShiftType? linkedShiftType,
    bool clearLinkedShiftType = false,
    int? relativeOffsetMinutes,
    bool clearRelativeOffset = false,
    bool? isCriticalShift,
    String? soundKey,
    int? weekdaysBitmask,
    bool? autoDeleteAfterFiring,
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
        relativeOffsetMinutes: clearRelativeOffset
            ? null
            : (relativeOffsetMinutes ?? this.relativeOffsetMinutes),
        isCriticalShift: isCriticalShift ?? this.isCriticalShift,
        soundKey: soundKey ?? this.soundKey,
        weekdaysBitmask: weekdaysBitmask ?? this.weekdaysBitmask,
        autoDeleteAfterFiring:
            autoDeleteAfterFiring ?? this.autoDeleteAfterFiring,
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
          relativeOffsetMinutes == other.relativeOffsetMinutes &&
          isCriticalShift == other.isCriticalShift &&
          soundKey == other.soundKey &&
          weekdaysBitmask == other.weekdaysBitmask &&
          autoDeleteAfterFiring == other.autoDeleteAfterFiring;

  @override
  int get hashCode => Object.hash(
        id,
        minutesOfDay,
        label,
        repeatType,
        enabled,
        linkedShiftType,
        relativeOffsetMinutes,
        isCriticalShift,
        soundKey,
        weekdaysBitmask,
        autoDeleteAfterFiring,
      );

  @override
  String toString() =>
      'AppAlarm(id: $id, time: $minutesOfDay, label: "$label", '
      'repeat: $repeatType, enabled: $enabled, '
      'linkedShiftType: $linkedShiftType, '
      'relativeOffsetMinutes: $relativeOffsetMinutes, '
      'isCriticalShift: $isCriticalShift, soundKey: $soundKey, '
      'weekdaysBitmask: $weekdaysBitmask, '
      'autoDeleteAfterFiring: $autoDeleteAfterFiring)';
}

/// Whether the alarm [a] should be permanently deleted from Hive the instant it
/// is dismissed, rather than left as a fired, stale config. Pure so the three
/// dismiss sites (in-app wake screen, foreground dispatcher, killed-app
/// background isolate) share one decision and one unit-test target. `null`
/// (record already gone, or no `appAlarmId` in the payload) → never delete.
/// Only one-time alarms with the flag qualify — `autoDeleteAfterFiring` is only
/// ever set on one-time alarms, but the explicit type guard is belt-and-braces.
bool shouldAutoDeleteOnDismiss(AppAlarm? a) =>
    a != null &&
    a.autoDeleteAfterFiring &&
    a.repeatType == AppAlarmRepeatType.oneTime;
