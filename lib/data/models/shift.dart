import 'package:hive_ce/hive.dart';

import 'shift_type.dart';

part 'shift.g.dart';

@HiveType(typeId: 1)
class Shift {
  Shift({
    required this.id,
    required DateTime date,
    required this.type,
    required this.startMinutes,
    required this.endMinutes,
    this.note,
    this.isMuted = false,
    this.isAcknowledged = false,
    this.snoozedUntil,
    this.cycleId,
    this.isAlarmSkipped = false,
    this.isAdHoc = false,
    this.isArchived = false,
    this.isPaused = false,
    this.pauseReason,
    this.dismissedAlarmIds = const [],
  })  : date = DateTime(date.year, date.month, date.day),
        assert(
          startMinutes >= 0 && startMinutes < 1440,
          'startMinutes must be 0..1439',
        ),
        assert(
          endMinutes >= 0 && endMinutes < 1440,
          'endMinutes must be 0..1439',
        );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final ShiftType type;

  @HiveField(3)
  final int startMinutes;

  @HiveField(4)
  final int endMinutes;

  @HiveField(5)
  final String? note;

  // Suppresses alarm scheduling for this shift without removing it from the
  // roster. The AlarmEngine treats `isMuted == true` as "not desired" and
  // its existing orphan-cancellation cleans up any pending OS alarm; toggling
  // back to false brings the alarm back. `defaultValue: false` makes records
  // serialized before this field was introduced read back as unmuted.
  @HiveField(6, defaultValue: false)
  final bool isMuted;

  // Set by the Dismiss notification action (foreground or background isolate)
  // once the user has handled this occurrence's alarm. The AlarmEngine treats
  // an acknowledged shift as "not desired" so the alarm is not re-scheduled
  // for the same occurrence on the next reconcile / cold start. Per-occurrence
  // and persistent: once dismissed, the alarm does not come back for that
  // date. `defaultValue: false` keeps legacy records readable.
  @HiveField(7, defaultValue: false)
  final bool isAcknowledged;

  // Set by the Snooze notification action. When non-null and still in the
  // future, the AlarmEngine pins this shift's desired fireAt to this instant
  // instead of `startDateTime - leadTime`, so a background-isolate reschedule
  // survives a cold start (the engine reconciles to the same time). Nullable
  // (no `defaultValue` needed); cleared implicitly when the snoozed alarm
  // fires and is dismissed.
  @HiveField(8)
  final DateTime? snoozedUntil;

  // Parent ShiftCycle id. Stamped by `ShiftGenerator` on every shift it
  // emits so `CycleService.deleteCycle` can find a cycle's children
  // without the cycle having to maintain its own child list. Null for
  // shifts that pre-date this feature (legacy records read back as
  // `null`) and for shifts added manually via the editor modal — those
  // shifts are independent of any cycle and are never touched by
  // cascade-delete. Once stamped, the value never changes: cycleId is
  // not exposed in any edit flow.
  @HiveField(9)
  final String? cycleId;

  // LEGACY whole-shift "skip the next alarm" flag — formerly written by the
  // Dashboard's "Dismiss Upcoming Alarm" early-skip. RETIRED AS A WRITE
  // TARGET: the early-skip now records per-ring dismissals in
  // [dismissedAlarmIds] instead, so skipping one alarm no longer silences the
  // shift's other alarms. Still READ by the projector (a shift already
  // carrying `true` from an older build keeps all its rings suppressed), so
  // the field must not be removed. Deliberately DISTINCT from
  // `isAcknowledged`: `_findNext` on the Dashboard filters out acknowledged
  // shifts — reusing ack here would wrongly drop the shift from the
  // next-shift card. `defaultValue: false` keeps legacy records readable.
  @HiveField(10, defaultValue: false)
  final bool isAlarmSkipped;

  // Phase-3 AD-HOC marker. True ONLY for single, non-rotating shifts inserted
  // via the Manage tab's "Add Custom Shift" editor (`ShiftEditorModal`).
  // Rotation shifts emitted by `ShiftGenerator` leave this false. This is the
  // SOLE discriminator the self-cleaning archive sweep keys off — never
  // `cycleId` — so a future cycle-less-but-not-ad-hoc shift can never be swept.
  // `defaultValue: false` makes every pre-existing record (and every rotation
  // shift) read back as non-ad-hoc.
  @HiveField(11, defaultValue: false)
  final bool isAdHoc;

  // Archive tombstone for an EXPIRED ad-hoc shift. The init-time sweep
  // (`archiveExpiredAdHocShifts`) flips this true once an ad-hoc shift's end is
  // more than the grace window (24h) in the past. The Shift is NEVER deleted —
  // shifts are immutable history; the calendar is the user's work record they
  // verify payslips against, and ad-hoc shifts are explicitly backfillable a
  // year into the past. An archived shift stays in Hive and still renders in
  // the historical timeline; it is only excluded from the alarm engine's active
  // desired-set computation (see AlarmSyncService). `defaultValue: false` keeps
  // legacy records readable.
  @HiveField(12, defaultValue: false)
  final bool isArchived;

  // EXCEPTION LAYER. When true the shift is PAUSED/CANCELLED for that day — the
  // user isn't working it (sick, annual leave, public holiday, …). The shift
  // STAYS on the calendar as a historical record (never deleted), rendered
  // muted/struck-through, and `AlarmSyncService` skips it so no alarm fires.
  // Like [isMuted] it suppresses scheduling, but it's a distinct, user-facing
  // "day off" carrying a [pauseReason] rather than the silent per-occurrence
  // mute. `defaultValue: false` keeps pre-exception-layer records readable.
  @HiveField(13, defaultValue: false)
  final bool isPaused;

  // Optional reason shown beside the paused state — a preset ("Sick", "Annual
  // Leave", "Public Holiday") or free text. Null when not paused, or paused
  // without a stated reason. Nullable, so no `defaultValue` is needed.
  @HiveField(14)
  final String? pauseReason;

  // PER-OCCURRENCE dismissal set: the AppAlarm rule ids whose ring for THIS
  // shift date the user has dismissed (slide/shake on the native AlarmActivity,
  // or the 15-min auto-timeout). A shift with several linked alarms (e.g. a
  // 60-min lead, a 30-min lead and an exact-time ring before the same Day
  // shift) accumulates one entry per dismissed ring; the projection suppresses
  // ONLY those rings, so dismissing the first alarm can never tear down its
  // still-pending siblings. Contrast [isAcknowledged], which is the WHOLE-SHIFT
  // blanket ack — still written by legacy ledger entries that carry no alarm
  // identity, and still honoured as "every ring handled".
  // `defaultValue: []` keeps pre-existing records readable.
  @HiveField(15, defaultValue: [])
  final List<String> dismissedAlarmIds;

  /// Whether this occurrence's alarm has already been HANDLED at [now] —
  /// dismissed ([isAcknowledged]) or pushed forward by a still-active snooze
  /// ([snoozedUntil] in the future).
  ///
  /// THE shared predicate between `WakeUpScreen`'s self-destruct rule and the
  /// cold-boot wake-route gate in `main.dart`, so the two can never diverge: a
  /// payload whose shift is handled must never (re)surface a wake screen — the
  /// "Zombie UI" bug where a Dismiss from the notification panel (killed app)
  /// stopped the audio but a later cold boot still routed to a dead
  /// WakeUpScreen off the stale FSI payload.
  ///
  /// Deliberately EXCLUDES [isMuted] / [isAlarmSkipped]: those suppress future
  /// *scheduling*, but if an alarm somehow fired anyway the wake screen is the
  /// only dismiss surface and must not be gated away.
  bool isAlarmHandledAt(DateTime now) =>
      isAcknowledged || (snoozedUntil != null && snoozedUntil!.isAfter(now));

  bool get isOvernight => endMinutes <= startMinutes;

  int get durationMinutes => isOvernight
      ? endMinutes + 1440 - startMinutes
      : endMinutes - startMinutes;

  // Calendar-math constructors instead of `date.add(Duration(...))`.
  // `Duration` is wall-clock-time arithmetic — adding `Duration(days: 1)`
  // to local midnight on a spring-forward day lands at 01:00 the next
  // day, not midnight, because that 24-hour interval crosses the lost
  // hour. `DateTime(y, m, d + n, h, mm)` resolves to the local time on
  // the target calendar day, which is what every caller actually wants
  // (the alarm engine derives `fireAt` from `startDateTime`; a 1-hour
  // DST drift here means alarms fire at the wrong wall-clock time).
  DateTime get startDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        startMinutes ~/ 60,
        startMinutes % 60,
      );

  DateTime get endDateTime => isOvernight
      ? DateTime(
          date.year,
          date.month,
          date.day + 1,
          endMinutes ~/ 60,
          endMinutes % 60,
        )
      : DateTime(
          date.year,
          date.month,
          date.day,
          endMinutes ~/ 60,
          endMinutes % 60,
        );

  // `clearSnoozedUntil: true` lets a caller (e.g. an alarm-fired handler or
  // a shift-edit flow) wipe a pending snooze. Without it, `snoozedUntil: null`
  // in copyWith would be indistinguishable from "leave unchanged".
  //
  // `cycleId` deliberately has no `clear` flag — the generator stamps it
  // once and nothing else should ever wipe it. A copyWith that wants to
  // re-stamp the parent (rare; only the generator does this) can pass the
  // new value explicitly.
  Shift copyWith({
    String? id,
    DateTime? date,
    ShiftType? type,
    int? startMinutes,
    int? endMinutes,
    String? note,
    bool? isMuted,
    bool? isAcknowledged,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    String? cycleId,
    bool? isAlarmSkipped,
    bool? isAdHoc,
    bool? isArchived,
    bool? isPaused,
    String? pauseReason,
    bool clearPauseReason = false,
    List<String>? dismissedAlarmIds,
  }) =>
      Shift(
        id: id ?? this.id,
        date: date ?? this.date,
        type: type ?? this.type,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        note: note ?? this.note,
        isMuted: isMuted ?? this.isMuted,
        isAcknowledged: isAcknowledged ?? this.isAcknowledged,
        snoozedUntil:
            clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
        cycleId: cycleId ?? this.cycleId,
        isAlarmSkipped: isAlarmSkipped ?? this.isAlarmSkipped,
        isAdHoc: isAdHoc ?? this.isAdHoc,
        isArchived: isArchived ?? this.isArchived,
        isPaused: isPaused ?? this.isPaused,
        // `clearPauseReason: true` wipes the reason (un-pause / change of mind);
        // without it `pauseReason: null` would be indistinguishable from "leave
        // unchanged" — same idiom as `clearSnoozedUntil`.
        pauseReason:
            clearPauseReason ? null : (pauseReason ?? this.pauseReason),
        dismissedAlarmIds: dismissedAlarmIds ?? this.dismissedAlarmIds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shift &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          type == other.type &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes &&
          note == other.note &&
          isMuted == other.isMuted &&
          isAcknowledged == other.isAcknowledged &&
          snoozedUntil == other.snoozedUntil &&
          cycleId == other.cycleId &&
          isAlarmSkipped == other.isAlarmSkipped &&
          isAdHoc == other.isAdHoc &&
          isArchived == other.isArchived &&
          isPaused == other.isPaused &&
          pauseReason == other.pauseReason &&
          _sameIds(dismissedAlarmIds, other.dismissedAlarmIds);

  // Element-wise list equality (pure Dart — no foundation.listEquals here).
  static bool _sameIds(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        type,
        startMinutes,
        endMinutes,
        note,
        isMuted,
        isAcknowledged,
        snoozedUntil,
        cycleId,
        isAlarmSkipped,
        isAdHoc,
        isArchived,
        isPaused,
        pauseReason,
        Object.hashAll(dismissedAlarmIds),
      );

  @override
  String toString() =>
      'Shift(id: $id, date: $date, type: $type, '
      'start: $startMinutes, end: $endMinutes, note: $note, '
      'isMuted: $isMuted, isAcknowledged: $isAcknowledged, '
      'snoozedUntil: $snoozedUntil, cycleId: $cycleId, '
      'isAlarmSkipped: $isAlarmSkipped, isAdHoc: $isAdHoc, '
      'isArchived: $isArchived, isPaused: $isPaused, '
      'pauseReason: $pauseReason, dismissedAlarmIds: $dismissedAlarmIds)';
}
