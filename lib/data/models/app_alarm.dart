import 'package:hive_ce/hive.dart';

import '../../alarms/alarm_sound.dart';
import 'ringtone_source.dart';
import 'shift_type.dart';

export 'ringtone_source.dart' show RingtoneSource;

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
/// **Timing model (followsRotation):** a follows-rotation alarm has two mutually
/// exclusive timing modes, selected by [isExactTime]:
///   * **Lead-time (default, `isExactTime == false`):** fire at
///     `shiftStart − leadTime`, where `leadTime` is the per-alarm
///     [relativeOffsetMinutes] when set (an OVERRIDE), else the global
///     [AlarmSettings.leadTime] (the PRIMARY default). This tracks the shift —
///     move the shift and the alarm follows.
///   * **Exact-time (`isExactTime == true`):** fire at the absolute
///     [exactTimeMinutes] on each matching shift's DATE, ignoring the lead time
///     entirely. Still roster-anchored (it only rings on days the linked shift
///     occurs) but pinned to a fixed wall-clock time the user chose.
///
/// The fire-time arithmetic for BOTH modes lives in one place —
/// `rotationAlarmFireAt` — so the engine and the Dashboard preview never drift.
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
    this.customRingtoneUri,
    this.customRingtoneName,
    this.ringtoneSource = RingtoneSource.classic,
    this.isExactTime = false,
    this.exactTimeMinutes,
    this.skippedThrough,
  })  : assert(
          minutesOfDay >= 0 && minutesOfDay < 1440,
          'minutesOfDay must be 0..1439',
        ),
        assert(
          relativeOffsetMinutes == null || relativeOffsetMinutes > 0,
          'relativeOffsetMinutes, when set, must be positive — a zero/negative '
          'offset would fire at or after the shift starts, defeating the point',
        ),
        assert(
          exactTimeMinutes == null ||
              (exactTimeMinutes >= 0 && exactTimeMinutes < 1440),
          'exactTimeMinutes, when set, must be a valid minute-of-day (0..1439)',
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

  /// Legacy opt-in (one-time only) to delete the record from Hive after it
  /// fires. NOTE: one-time alarms are now ALWAYS removed after firing (see
  /// [shouldDeleteAfterFiring]) — a fired one-time left in Hive re-projects
  /// daily — so this flag is effectively subsumed and the create/edit toggle is
  /// redundant; it's retained for the persisted schema (HiveField 11) and as an
  /// explicit opt-in should a non-one-time alarm type ever want post-fire
  /// cleanup. The native [AlarmActivity] dismiss / auto-timeout records the fired
  /// `appAlarmId` in the `pending_alarm_deletes` ledger, which the Dart drain
  /// replays through [deleteAlarmAfterFiring]. Legacy records (no field 11) read
  /// back `false`.
  @HiveField(11, defaultValue: false)
  final bool autoDeleteAfterFiring;

  /// Per-alarm custom ringtone — the durable vault path ([RingtoneSource.vault])
  /// or `content://` system URI ([RingtoneSource.system]) this alarm plays, or
  /// null for a bundled tone ([RingtoneSource.classic], the default). Migrated
  /// here from the (formerly global) `AlarmSettings` so each alarm carries its
  /// own audio. Non-null routes the firing notification to the silent channel
  /// and `WakeUpScreen` plays it natively. Legacy records (no field 12) read
  /// back null.
  @HiveField(12)
  final String? customRingtoneUri;

  /// Human-readable name of [customRingtoneUri] (what the editor shows), or null
  /// for a bundled tone. Legacy records (no field 13) read back null.
  @HiveField(13)
  final String? customRingtoneName;

  /// How to interpret [customRingtoneUri] — see [RingtoneSource]. Defaults to
  /// [RingtoneSource.classic] (bundled tone); legacy records (no field 14) read
  /// back classic via the adapter.
  @HiveField(14)
  final RingtoneSource ringtoneSource;

  /// Exact-time mode for a followsRotation alarm. When true the alarm fires at
  /// the absolute [exactTimeMinutes] on each matching shift's date instead of
  /// `shiftStart − leadTime` — the lead time (global default AND any
  /// [relativeOffsetMinutes] override) is ignored. Default false (lead-time
  /// mode); legacy records (no field 15) read back false via the adapter.
  /// Meaningless for weekly / oneTime alarms (they already fire at an absolute
  /// [minutesOfDay]); the create sheet only ever sets it on followsRotation.
  @HiveField(15, defaultValue: false)
  final bool isExactTime;

  /// The absolute fire time (minute-of-day, 0..1439) for an [isExactTime]
  /// followsRotation alarm — e.g. `255` for 04:15. Null in lead-time mode (and
  /// on legacy records, no field 16). When [isExactTime] is true but this is
  /// null, the fire-time math falls back to lead-time mode rather than crashing.
  @HiveField(16)
  final int? exactTimeMinutes;

  /// PER-OCCURRENCE skip for SHIFT-LESS alarms (weekly; defensively honoured
  /// for one-time too): the projection suppresses any occurrence whose fireAt
  /// is at-or-before this instant. The Dashboard's early-skip writes the
  /// skipped ring's fireAt here — next week's occurrence fires later, so it
  /// stays armed. This is the shift-less counterpart of
  /// `Shift.dismissedAlarmIds`: rotation rings record their dismissal on the
  /// shift row; weekly/one-time rings have no shift, so the rule itself
  /// carries it. Riding the AppAlarm (not a side store) is load-bearing — the
  /// upsert flows through the watched alarms stream, so the engine reconciles
  /// (cancelling the pending OS alarm) and every UI projection retargets,
  /// with zero extra wiring.
  ///
  /// Only ever advanced (monotonic max at the write site); a past instant is
  /// inert because the projector's future-only gate already excludes rings
  /// at-or-before now, so it never needs clearing. Never consulted for
  /// follows-rotation rings. Null on legacy records (no field 17).
  ///
  /// NOT used for skipping a one-time alarm: `_nextDailyOccurrence` rolls a
  /// one-time forward daily, so a suppressed-instant skip would resurrect it
  /// TOMORROW — the early-skip disables the rule (`enabled: false`) instead.
  @HiveField(17)
  final DateTime? skippedThrough;

  /// The exact-time fire clock when exact-time mode is ACTIVE and well-formed,
  /// else null (= lead-time mode). This is the single mode-decision gate shared
  /// by the engine (`rotationAlarmFireAt`) and every UI projection
  /// ([displayFireClockMinutes]) — including the defensive malformed-record
  /// rule ([isExactTime] true but a null clock falls back to lead-time math
  /// rather than crashing) — so the engine and the display can never disagree
  /// about WHICH mode an alarm is in.
  int? get activeExactTimeMinutes => isExactTime ? exactTimeMinutes : null;

  /// The lead applied in lead-time mode: this alarm's [relativeOffsetMinutes]
  /// override when set, else the caller's [globalLeadMinutes] default.
  int leadMinutesWith(int globalLeadMinutes) =>
      relativeOffsetMinutes ?? globalLeadMinutes;

  /// The clock face (minute-of-day, 0..1439) this follows-rotation alarm will
  /// RING for a shift starting at [shiftStartMinutes] — the single display
  /// source of truth for every UI text widget (Alarms-tab card hero, create
  /// sheet, etc.). Respects [isExactTime]: returns [exactTimeMinutes] in
  /// exact-time mode, else `shiftStart − lead` wrapped across midnight (a
  /// 90-min lead before a 00:30 shift renders 23:00).
  ///
  /// Display projection ONLY — the authoritative date-anchored instant the OS
  /// is armed with comes from `rotationAlarmFireAt`, which shares
  /// [activeExactTimeMinutes] / [leadMinutesWith] so the two stay in lock-step.
  /// (Field bug this fixes: an exact-time 04:15 alarm was armed correctly but
  /// cards still rendered the old `shiftStart − leadTime` hand-math → 05:00.)
  int displayFireClockMinutes({
    required int shiftStartMinutes,
    required int globalLeadMinutes,
  }) {
    final exact = activeExactTimeMinutes;
    if (exact != null) return exact;
    final raw =
        (shiftStartMinutes - leadMinutesWith(globalLeadMinutes)) % 1440;
    return raw < 0 ? raw + 1440 : raw;
  }

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
    String? customRingtoneUri,
    String? customRingtoneName,
    RingtoneSource? ringtoneSource,
    bool? isExactTime,
    int? exactTimeMinutes,
    bool clearExactTime = false,
    DateTime? skippedThrough,
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
        customRingtoneUri: customRingtoneUri ?? this.customRingtoneUri,
        customRingtoneName: customRingtoneName ?? this.customRingtoneName,
        ringtoneSource: ringtoneSource ?? this.ringtoneSource,
        isExactTime: isExactTime ?? this.isExactTime,
        exactTimeMinutes: clearExactTime
            ? null
            : (exactTimeMinutes ?? this.exactTimeMinutes),
        // No clear flag: the skip watermark only ever advances (a past value
        // is inert), so `null` always means "leave unchanged".
        skippedThrough: skippedThrough ?? this.skippedThrough,
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
          autoDeleteAfterFiring == other.autoDeleteAfterFiring &&
          customRingtoneUri == other.customRingtoneUri &&
          customRingtoneName == other.customRingtoneName &&
          ringtoneSource == other.ringtoneSource &&
          isExactTime == other.isExactTime &&
          exactTimeMinutes == other.exactTimeMinutes &&
          skippedThrough == other.skippedThrough;

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
        customRingtoneUri,
        customRingtoneName,
        ringtoneSource,
        isExactTime,
        exactTimeMinutes,
        skippedThrough,
      );

  @override
  String toString() =>
      'AppAlarm(id: $id, time: $minutesOfDay, label: "$label", '
      'repeat: $repeatType, enabled: $enabled, '
      'linkedShiftType: $linkedShiftType, '
      'relativeOffsetMinutes: $relativeOffsetMinutes, '
      'isCriticalShift: $isCriticalShift, soundKey: $soundKey, '
      'weekdaysBitmask: $weekdaysBitmask, '
      'autoDeleteAfterFiring: $autoDeleteAfterFiring, '
      'customRingtoneUri: $customRingtoneUri, '
      'customRingtoneName: $customRingtoneName, '
      'ringtoneSource: $ringtoneSource, '
      'isExactTime: $isExactTime, exactTimeMinutes: $exactTimeMinutes, '
      'skippedThrough: $skippedThrough)';
}

/// Whether the alarm [a] should be permanently removed from Hive once it has
/// fired and been dismissed (or auto-timed-out), rather than left to re-project.
///
/// EVERY one-time alarm qualifies: a one-time alarm fires exactly once, so if it
/// lingers the engine's daily next-occurrence projection re-arms it the
/// following day — a one-shot alarm silently becoming a daily cycle (the bug
/// this guards). Gating on `repeatType == oneTime` (rather than the
/// [AppAlarm.autoDeleteAfterFiring] opt-in) both covers every flagged alarm —
/// the flag is only ever set on one-time alarms, so one-time subsumes it — AND
/// protects recurring alarms: a weekly/follows-rotation rule is never cleaned up
/// after firing even if some bug set the flag on it. `null` (record already
/// gone, or no `appAlarmId` in the payload) → never delete. Pure so the dismiss
/// path and its unit tests share one decision.
bool shouldDeleteAfterFiring(AppAlarm? a) =>
    a != null && a.repeatType == AppAlarmRepeatType.oneTime;
