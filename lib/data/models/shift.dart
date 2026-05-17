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
          cycleId == other.cycleId;

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
      );

  @override
  String toString() =>
      'Shift(id: $id, date: $date, type: $type, '
      'start: $startMinutes, end: $endMinutes, note: $note, '
      'isMuted: $isMuted, isAcknowledged: $isAcknowledged, '
      'snoozedUntil: $snoozedUntil, cycleId: $cycleId)';
}
