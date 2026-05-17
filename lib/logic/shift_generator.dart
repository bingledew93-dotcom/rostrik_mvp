import 'package:uuid/uuid.dart';

import '../data/models/shift.dart';
import '../data/models/shift_pattern.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/shift_repository.dart';

/// Bulk-generates a block of consecutive same-pattern shifts.
///
/// Parameters describe the *pattern* (start time, end time, type) and
/// the *block* (start date, length). One [Shift] is produced per
/// consecutive day, all sharing the same minute-of-day start/end pair.
///
/// Overnight handling lives in the [Shift] model — `isOvernight` and
/// `endDateTime` derive +1 day when `endMinutes <= startMinutes`. The
/// generator deliberately does NOT shift dates per-shift; it just
/// stores the minute-of-day pair on each consecutive calendar date and
/// lets the model resolve cross-midnight on read. Shifting dates here
/// would double-count and break alarm scheduling for overnight blocks.
///
/// Existing shifts are not deduplicated — every generated shift gets a
/// fresh UUID, so callers may end up with multiple shifts on the same
/// date if a block overlaps an existing roster. V1 leaves this to the
/// caller; a future pass can offer "replace overlap" semantics.
class ShiftGenerator {
  ShiftGenerator({
    required ShiftRepository repository,
    Uuid uuid = const Uuid(),
  })  : _repository = repository,
        _uuid = uuid;

  final ShiftRepository _repository;
  final Uuid _uuid;

  /// Pure builder — produces the list without persisting. Useful for
  /// tests and (future) preview UIs.
  List<Shift> generateBlock({
    required DateTime startDate,
    required int startMinutes,
    required int endMinutes,
    required int consecutiveDays,
    required ShiftType shiftType,
  }) {
    assert(consecutiveDays > 0, 'consecutiveDays must be positive');
    assert(
      shiftType != ShiftType.off,
      'Off shifts have no time range — use the single-shift editor instead',
    );
    assert(startMinutes >= 0 && startMinutes < 1440, 'startMinutes 0..1439');
    assert(endMinutes >= 0 && endMinutes < 1440, 'endMinutes 0..1439');
    assert(startMinutes != endMinutes, 'zero-duration shift is meaningless');

    final shifts = <Shift>[];
    for (var i = 0; i < consecutiveDays; i++) {
      final date = startDate.add(Duration(days: i));
      shifts.add(Shift(
        id: _uuid.v4(),
        date: date,
        type: shiftType,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ));
    }
    return shifts;
  }

  /// Generates and persists all shifts for one full cycle of [pattern],
  /// starting on [startDate].
  ///
  /// [dayStartMinutes] / [dayEndMinutes] apply to every Day/Afternoon segment.
  /// [nightStartMinutes] / [nightEndMinutes] apply to every Night segment.
  /// Off segments are stored with startMinutes=0, endMinutes=0, matching how
  /// the shift editor stores manually created off days.
  Future<List<Shift>> generatePattern({
    required DateTime startDate,
    required ShiftPattern pattern,
    required int dayStartMinutes,
    required int dayEndMinutes,
    int nightStartMinutes = 22 * 60,
    int nightEndMinutes = 6 * 60,
  }) async {
    final allShifts = <Shift>[];
    var cursor = startDate;

    for (final segment in pattern.segments) {
      if (segment.type == ShiftType.off) {
        for (var i = 0; i < segment.days; i++) {
          allShifts.add(Shift(
            id: _uuid.v4(),
            date: cursor.add(Duration(days: i)),
            type: ShiftType.off,
            startMinutes: 0,
            endMinutes: 0,
          ));
        }
      } else {
        final startMins = segment.type == ShiftType.night
            ? nightStartMinutes
            : dayStartMinutes;
        final endMins = segment.type == ShiftType.night
            ? nightEndMinutes
            : dayEndMinutes;
        allShifts.addAll(generateBlock(
          startDate: cursor,
          startMinutes: startMins,
          endMinutes: endMins,
          consecutiveDays: segment.days,
          shiftType: segment.type,
        ));
      }
      cursor = cursor.add(Duration(days: segment.days));
    }

    for (final shift in allShifts) {
      await _repository.upsert(shift);
    }
    return allShifts;
  }

  /// Generates the block and persists each shift via the repository's
  /// upsert. The AlarmEngine's stream subscription picks up the writes
  /// and reschedules the OS alarms (debounced) — this method does not
  /// touch the engine directly.
  Future<List<Shift>> generateAndPersist({
    required DateTime startDate,
    required int startMinutes,
    required int endMinutes,
    required int consecutiveDays,
    required ShiftType shiftType,
  }) async {
    final shifts = generateBlock(
      startDate: startDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      consecutiveDays: consecutiveDays,
      shiftType: shiftType,
    );
    for (final shift in shifts) {
      await _repository.upsert(shift);
    }
    return shifts;
  }
}
