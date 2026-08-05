import 'package:hive_ce/hive.dart';

part 'calendar_activity.g.dart';

/// What kind of non-shift entry this is. Purely a display/semantics tag — the
/// alarm engine never reads [CalendarActivity] at all, so no kind can affect
/// shift-alarm scheduling.
@HiveType(typeId: 9)
enum ActivityKind {
  @HiveField(0)
  event,
  @HiveField(1)
  task,
  @HiveField(2)
  birthday,
}

/// A user-added calendar entry that is NOT a shift — an event, task, or
/// birthday. Phase 3 lets the calendar double as a normal calendar without
/// touching the shift/alarm machinery: activities live in their own Hive box,
/// their own repository, and are never consulted by `AlarmSyncService` or the
/// projection. Rendering and (optional) reminders are entirely separate paths.
///
/// A reminder, when set, fires on a SEPARATE lightweight notification channel —
/// never `setAlarmClock`, never the full-screen wake activity — so it is fully
/// isolated from the shift-alarm reliability path.
@HiveType(typeId: 8)
class CalendarActivity {
  CalendarActivity({
    required this.id,
    required DateTime date,
    required this.title,
    required this.kind,
    this.note,
    this.timeMinutes,
    this.reminderAt,
    this.isDone = false,
  })  : date = DateTime(date.year, date.month, date.day),
        assert(
          timeMinutes == null || (timeMinutes >= 0 && timeMinutes < 1440),
          'timeMinutes, when set, must be a valid minute-of-day (0..1439)',
        );

  @HiveField(0)
  final String id;

  /// The calendar day this activity belongs to (normalised to local midnight).
  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final ActivityKind kind;

  @HiveField(4)
  final String? note;

  /// Minute-of-day (0..1439) the activity is at, or null for an all-day entry
  /// (the natural default for a birthday). Display + reminder-anchor only.
  @HiveField(5)
  final int? timeMinutes;

  /// Absolute instant a reminder notification should fire, or null for no
  /// reminder. Stored absolute (not an offset) so it's unambiguous to schedule
  /// and survives independently of the activity's day. Delivered on the
  /// isolated activity-reminder channel.
  @HiveField(6)
  final DateTime? reminderAt;

  /// Task completion tick. Meaningless for event/birthday (stays false); the
  /// task UI toggles it. `defaultValue: false` keeps legacy records readable.
  @HiveField(7, defaultValue: false)
  final bool isDone;

  bool get isAllDay => timeMinutes == null;
  bool get hasReminder => reminderAt != null;

  CalendarActivity copyWith({
    String? id,
    DateTime? date,
    String? title,
    ActivityKind? kind,
    String? note,
    bool clearNote = false,
    int? timeMinutes,
    bool clearTime = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool? isDone,
  }) =>
      CalendarActivity(
        id: id ?? this.id,
        date: date ?? this.date,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        note: clearNote ? null : (note ?? this.note),
        timeMinutes: clearTime ? null : (timeMinutes ?? this.timeMinutes),
        reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
        isDone: isDone ?? this.isDone,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarActivity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          title == other.title &&
          kind == other.kind &&
          note == other.note &&
          timeMinutes == other.timeMinutes &&
          reminderAt == other.reminderAt &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        title,
        kind,
        note,
        timeMinutes,
        reminderAt,
        isDone,
      );

  @override
  String toString() => 'CalendarActivity(id: $id, date: $date, '
      'title: "$title", kind: $kind, note: $note, timeMinutes: $timeMinutes, '
      'reminderAt: $reminderAt, isDone: $isDone)';
}
