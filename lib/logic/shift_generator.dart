import 'package:uuid/uuid.dart';

import '../data/models/cycle_block.dart';
import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import 'cycle_resolver.dart';
import 'rotation_pattern.dart';
import 'rotation_pattern_validator.dart';
import 'shift_block.dart';

/// Bulk-generates a block of consecutive same-pattern shifts AND the
/// parent [ShiftCycle] that owns them.
///
/// Every shift this class persists is stamped with `cycleId` pointing at
/// a `ShiftCycle` record written in the same call, which is what makes
/// `CycleService.deleteCycle` able to cascade-delete by id later.
///
/// Overnight handling lives in the [Shift] model — `isOvernight` and
/// `endDateTime` derive +1 day when `endMinutes <= startMinutes`. The
/// generator deliberately does NOT shift dates per-shift; it just
/// stores the minute-of-day pair on each consecutive calendar date and
/// lets the model resolve cross-midnight on read.
///
/// Same-date conflict detection: before persisting, the generator runs
/// [findTimeOverlaps] on the union of (would-be new shifts ∪ existing
/// shifts in the same date range) and throws [RosterGenerationException]
/// if any pair conflicts. Split shifts on the same date are allowed
/// (06:00–10:00 + 15:00–19:00); only TIME-overlapping pairs reject.
class ShiftGenerator {
  ShiftGenerator({
    required ShiftRepository shifts,
    required ShiftCycleRepository cycles,
    Uuid uuid = const Uuid(),
    DateTime Function() clock = _systemClock,
  })  : _shifts = shifts,
        _cycles = cycles,
        _uuid = uuid,
        _clock = clock;

  static DateTime _systemClock() => DateTime.now();

  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Pure builder — produces the list without persisting and without
  /// stamping a `cycleId`. Useful for tests and preview UIs.
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
      final date = _addCalendarDays(startDate, i);
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

  /// Template path: generates a contiguous block of same-type shifts AND
  /// the owning `ShiftCycle`, then persists both.
  ///
  /// Throws [RosterGenerationException] (without writing anything) if any
  /// of the new shifts would land on the same date as an existing shift
  /// with a time-overlapping range.
  Future<List<Shift>> generateAndPersist({
    required DateTime startDate,
    required int startMinutes,
    required int endMinutes,
    required int consecutiveDays,
    required ShiftType shiftType,
  }) async {
    final draft = generateBlock(
      startDate: startDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      consecutiveDays: consecutiveDays,
      shiftType: shiftType,
    );

    await _rejectIfTimeOverlap(draft);

    final cycleId = _uuid.v4();
    final endDateInclusive =
        draft.isEmpty ? draft.first.date : draft.last.date;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    // Anchored representation for the template path. The template is
    // conceptually a one-shot work block, not a recurring cycle, but the
    // app's "every cycle must be anchored" invariant requires we give
    // the resolver something to project. Pair the work block with a
    // 365-day Off pad so the Calendar paints the materialised work days
    // correctly and projects "no further commitments" for the rest of
    // the year. Past one full cycle (work + 365 off) the modulo would
    // wrap, but that's beyond the 365-day materialisation horizon.
    final cycleBlocks = <CycleBlock>[
      CycleBlock(
        type: shiftType,
        consecutiveDays: consecutiveDays,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
      const CycleBlock(type: ShiftType.off, consecutiveDays: 365),
    ];
    final cycle = ShiftCycle(
      id: cycleId,
      label: '${_typeLabel(shiftType)} block · $consecutiveDays day(s)',
      summary: _formatTimeRange(startMinutes, endMinutes),
      startDate: start,
      endDate: endDateInclusive,
      createdAt: _clock(),
      anchorDate: start,
      blocks: List<CycleBlock>.unmodifiable(cycleBlocks),
    );
    await _cycles.create(cycle);

    final stamped = <Shift>[];
    for (final s in draft) {
      final withCycle = s.copyWith(cycleId: cycleId);
      await _shifts.upsert(withCycle);
      stamped.add(withCycle);
    }
    return stamped;
  }

  /// Pattern path: expands a [RotationPattern] starting on [startDate],
  /// looping the pattern's blocks as many times as needed, and stops as
  /// soon as the cursor reaches [endDate] (exclusive). Writes a
  /// `ShiftCycle` parent and stamps every child with its `cycleId`.
  ///
  /// Validates the pattern's structural shape via [validateRotationPattern]
  /// and the post-merge time-conflict shape via [findTimeOverlaps]. On
  /// either failure throws [RosterGenerationException] and writes nothing.
  Future<List<Shift>> generateAndPersistPattern({
    required RotationPattern pattern,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final structuralErrors = validateRotationPattern(pattern);
    if (structuralErrors.isNotEmpty) {
      throw RosterGenerationException(structuralErrors.join('\n'));
    }

    // Normalise both bounds to local midnight up front. Without this, a
    // date carrying a time component propagates hours/minutes into every
    // cursor advance and the dates drift across DST boundaries.
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final stop = DateTime(endDate.year, endDate.month, endDate.day);
    assert(stop.isAfter(start), 'endDate must be strictly after startDate');

    final cycleId = _uuid.v4();
    final draft = <Shift>[];
    var cursor = start;
    while (cursor.isBefore(stop)) {
      for (final block in pattern.blocks) {
        for (var d = 0; d < block.consecutiveDays; d++) {
          // Re-check inside the inner loop so a partial block at the
          // tail of the range is honoured: stop the moment we hit
          // endDate rather than completing the current block.
          if (!cursor.isBefore(stop)) break;
          draft.add(Shift(
            id: _uuid.v4(),
            date: cursor,
            type: block.type,
            startMinutes: block.startMinutes,
            endMinutes: block.endMinutes,
            cycleId: cycleId,
          ));
          cursor = _addCalendarDays(cursor, 1);
        }
        if (!cursor.isBefore(stop)) break;
      }
    }

    await _rejectIfTimeOverlap(draft);

    final endDateInclusive =
        draft.isEmpty ? start : draft.last.date;
    final cycle = ShiftCycle(
      id: cycleId,
      label: pattern.label,
      summary: pattern.summary,
      startDate: start,
      endDate: endDateInclusive,
      createdAt: _clock(),
      patternId: pattern.id,
      anchorDate: start,
      blocks: _rotationBlocksToCycleBlocks(pattern.blocks),
    );
    await _cycles.create(cycle);

    for (final s in draft) {
      await _shifts.upsert(s);
    }
    return draft;
  }

  /// Custom-builder path: expands a list of positional [ShiftBlock]s
  /// across `cycleLengthDays * repeatCount` calendar days and persists
  /// the resulting shifts under a single [ShiftCycle].
  ///
  /// Unlike the rotation-pattern path, multiple blocks can occupy the
  /// SAME cycle-day position (split shifts). The structural validator
  /// ([validateCustomRoster]) verifies day-index bounds; the post-merge
  /// time-overlap validator ([findTimeOverlaps]) catches any pair of
  /// blocks whose times collide on the same calendar date. On either
  /// failure throws [RosterGenerationException] and writes nothing.
  Future<List<Shift>> generateAndPersistCustom({
    required String label,
    required DateTime startDate,
    required int cycleLengthDays,
    required int repeatCount,
    required List<ShiftBlock> blocks,
  }) async {
    if (repeatCount <= 0) {
      throw RosterGenerationException('Repeat count must be at least 1.');
    }
    final structuralErrors = validateCustomRoster(cycleLengthDays, blocks);
    if (structuralErrors.isNotEmpty) {
      throw RosterGenerationException(structuralErrors.join('\n'));
    }

    // Normalise the start to local midnight up front — same DST-drift
    // defence used by `generateAndPersistPattern`.
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final cycleId = _uuid.v4();
    final totalDays = cycleLengthDays * repeatCount;
    final draft = <Shift>[];

    for (var dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      final cyclePos = dayIdx % cycleLengthDays;
      final date = _addCalendarDays(start, dayIdx);
      for (final block in blocks) {
        if (cyclePos < block.startDayIndex) continue;
        if (cyclePos > block.endDayIndex) continue;
        draft.add(Shift(
          id: _uuid.v4(),
          date: date,
          type: block.type,
          startMinutes: block.startMinutes,
          endMinutes: block.endMinutes,
          cycleId: cycleId,
        ));
      }
    }

    if (draft.isEmpty) {
      // Defensive: the structural validator catches empty blocks, but a
      // pattern of all-zero day spans plus a 0-length cycle could in
      // principle slip through. Surface explicitly rather than create
      // an empty cycle row.
      throw RosterGenerationException(
        'No shifts would be generated. Check the block day ranges.',
      );
    }

    await _rejectIfTimeOverlap(draft);

    final endDateInclusive = _addCalendarDays(start, totalDays - 1);
    final cycle = ShiftCycle(
      id: cycleId,
      label: label.isEmpty ? 'Custom roster' : label,
      summary: 'Custom · $cycleLengthDays-day cycle · '
          '${blocks.length} block${blocks.length == 1 ? '' : 's'}'
          '${repeatCount == 1 ? '' : ' × $repeatCount'}',
      startDate: start,
      endDate: endDateInclusive,
      createdAt: _clock(),
      anchorDate: start,
      blocks: _foldCustomBlocksToCycleBlocks(cycleLengthDays, blocks),
    );
    await _cycles.create(cycle);

    for (final s in draft) {
      await _shifts.upsert(s);
    }
    return draft;
  }

  /// Anchored path: persists a [ShiftCycle] carrying the `anchorDate` +
  /// `blocks` data the modulo resolver needs, then materialises concrete
  /// [Shift] records for every calendar day in `[materialiseFrom,
  /// materialiseTo)` by calling [resolveShiftBlockForDate] per day.
  ///
  /// The cycle itself is conceptually infinite — the materialisation
  /// window is just the slice of days written into Hive for the alarm
  /// scheduler to consume. A future "extend horizon" task can re-run
  /// this path with a wider window without touching the cycle record
  /// (re-inserting the same `cycleId` would conflict; the future
  /// extender would call a separate `materialiseAnchoredRange` that
  /// only writes shifts).
  ///
  /// Validates: non-empty blocks, every block has positive
  /// `consecutiveDays`, minute fields in `[0, 1440)`, non-OFF blocks
  /// have a non-zero duration. On failure throws
  /// [RosterGenerationException] before any persistence call.
  Future<List<Shift>> generateAndPersistAnchored({
    required String label,
    required DateTime anchorDate,
    required List<CycleBlock> blocks,
    required DateTime materialiseFrom,
    required DateTime materialiseTo,
    String? summary,
  }) async {
    final structuralErrors = _validateCycleBlocks(blocks);
    if (structuralErrors.isNotEmpty) {
      throw RosterGenerationException(structuralErrors.join('\n'));
    }

    // Normalise all three dates to local midnight — same DST-drift
    // defence used by the other generate paths.
    final anchor = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
    );
    final from = DateTime(
      materialiseFrom.year,
      materialiseFrom.month,
      materialiseFrom.day,
    );
    final to = DateTime(
      materialiseTo.year,
      materialiseTo.month,
      materialiseTo.day,
    );
    if (!to.isAfter(from)) {
      throw RosterGenerationException(
        'materialiseTo must be strictly after materialiseFrom.',
      );
    }

    final cycleId = _uuid.v4();
    final draft = <Shift>[];
    var cursor = from;
    while (cursor.isBefore(to)) {
      final resolution = resolveShiftBlockForDate(
        target: cursor,
        anchor: anchor,
        blocks: blocks,
      );
      // Structural validation above guarantees a non-null resolution
      // for any cursor; the null check is defence-in-depth against a
      // future validator regression.
      if (resolution == null) break;
      draft.add(Shift(
        id: _uuid.v4(),
        date: cursor,
        type: resolution.block.type,
        startMinutes: resolution.block.startMinutes,
        endMinutes: resolution.block.endMinutes,
        cycleId: cycleId,
      ));
      cursor = _addCalendarDays(cursor, 1);
    }

    if (draft.isEmpty) {
      throw RosterGenerationException(
        'No shifts would be generated. Check the materialise window.',
      );
    }

    await _rejectIfTimeOverlap(draft);

    final cycleLen = blocks.fold<int>(0, (n, b) => n + b.consecutiveDays);
    final endDateInclusive = draft.last.date;
    final cycle = ShiftCycle(
      id: cycleId,
      label: label.isEmpty ? 'Anchored roster' : label,
      summary: summary ??
          'Anchored · $cycleLen-day cycle · '
              '${blocks.length} block${blocks.length == 1 ? '' : 's'}',
      startDate: from,
      endDate: endDateInclusive,
      createdAt: _clock(),
      anchorDate: anchor,
      blocks: List<CycleBlock>.unmodifiable(blocks),
    );
    await _cycles.create(cycle);

    for (final s in draft) {
      await _shifts.upsert(s);
    }
    return draft;
  }

  /// Extends an existing anchored [ShiftCycle] by materialising
  /// additional [Shift] records in `[from, to)` under the SAME cycleId
  /// — the rolling-horizon path used by the Invisible Extender.
  ///
  /// Idempotent on the date axis: any cursor day that already has a
  /// shift for `cycle.id` is skipped. So re-running the extender after
  /// a partial failure, or extending an overlapping range, writes only
  /// the missing days.
  ///
  /// Throws [RosterGenerationException] if [cycle] is not anchored,
  /// `to <= from`, or the new draft time-overlaps the existing roster.
  /// Does NOT create a new [ShiftCycle] row — the caller already owns
  /// one. The shift writes go through `_shifts.upsert` exactly like
  /// the other generate paths, so any stream watcher in the same
  /// isolate sees the new shifts on its next emission.
  Future<List<Shift>> materialiseAnchoredRange({
    required ShiftCycle cycle,
    required DateTime from,
    required DateTime to,
  }) async {
    if (!cycle.isAnchored) {
      throw RosterGenerationException(
        'materialiseAnchoredRange requires an anchored cycle '
        '(anchorDate + non-empty blocks).',
      );
    }
    final fromMidnight = DateTime(from.year, from.month, from.day);
    final toMidnight = DateTime(to.year, to.month, to.day);
    if (!toMidnight.isAfter(fromMidnight)) {
      throw RosterGenerationException(
        'materialise window is empty: to must be after from.',
      );
    }

    final existingDates = <DateTime>{
      for (final s in await _shifts.getByCycleId(cycle.id)) s.date,
    };

    final anchor = cycle.anchorDate!;
    final blocks = cycle.blocks!;
    final draft = <Shift>[];
    var cursor = fromMidnight;
    while (cursor.isBefore(toMidnight)) {
      if (!existingDates.contains(cursor)) {
        final resolution = resolveShiftBlockForDate(
          target: cursor,
          anchor: anchor,
          blocks: blocks,
        );
        // Cycle.isAnchored guaranteed non-empty blocks above; the
        // resolver only returns null for empty blocks, so this branch
        // is defence-in-depth.
        if (resolution != null) {
          draft.add(Shift(
            id: _uuid.v4(),
            date: cursor,
            type: resolution.block.type,
            startMinutes: resolution.block.startMinutes,
            endMinutes: resolution.block.endMinutes,
            cycleId: cycle.id,
          ));
        }
      }
      cursor = _addCalendarDays(cursor, 1);
    }

    if (draft.isEmpty) return const <Shift>[];

    await _rejectIfTimeOverlap(draft);

    for (final s in draft) {
      await _shifts.upsert(s);
    }
    return draft;
  }

  /// Structural validation mirroring [validateRotationPattern] but
  /// operating on [CycleBlock] (the persisted Hive type) instead of
  /// `RotationBlock` (the pure-logic type). Same error wording so the
  /// SnackBar surface remains uniform across generate paths.
  static List<String> _validateCycleBlocks(List<CycleBlock> blocks) {
    final errors = <String>[];
    if (blocks.isEmpty) {
      errors.add('Cycle has no blocks.');
      return errors;
    }
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final label = 'Block ${i + 1}';
      if (b.consecutiveDays <= 0) {
        errors.add('$label has zero or negative days.');
      }
      if (b.startMinutes < 0 || b.startMinutes >= 1440) {
        errors.add('$label start time is out of range.');
      }
      if (b.endMinutes < 0 || b.endMinutes >= 1440) {
        errors.add('$label end time is out of range.');
      }
      if (b.type != ShiftType.off && b.startMinutes == b.endMinutes) {
        errors.add('$label has the same start and end time.');
      }
    }
    return errors;
  }

  /// Compares the in-flight draft against the existing roster in the
  /// same date span and throws if any same-date pair has a time overlap.
  /// Throws BEFORE any persistence call so a rejected Generate writes
  /// nothing — the user sees a SnackBar, the box is unchanged.
  Future<void> _rejectIfTimeOverlap(List<Shift> draft) async {
    if (draft.isEmpty) return;
    // Read the existing roster in the draft's exact date span. `[from, to)`
    // semantics match `getInRange`: pass `lastDate + 1 day` as the upper
    // bound so the inclusive last date is part of the query.
    var minDate = draft.first.date;
    var maxDate = draft.first.date;
    for (final s in draft) {
      if (s.date.isBefore(minDate)) minDate = s.date;
      if (s.date.isAfter(maxDate)) maxDate = s.date;
    }
    final existing = await _shifts.getInRange(
      minDate,
      _addCalendarDays(maxDate, 1),
    );
    final union = [...existing, ...draft];
    final conflicts = findTimeOverlaps(union);
    if (conflicts.isEmpty) return;
    // One human-readable line per pair; surface the first few so the
    // SnackBar doesn't grow unbounded. (`min` would need a dart:math
    // import; the conditional is clearer.)
    final lines = <String>[];
    final shown = conflicts.length > 3 ? 3 : conflicts.length;
    for (var i = 0; i < shown; i++) {
      final (a, b) = conflicts[i];
      lines.add(
        'Shift blocks have overlapping times on '
        '${a.date.year}-${_pad2(a.date.month)}-${_pad2(a.date.day)} '
        '(${_pad2(a.startMinutes ~/ 60)}:${_pad2(a.startMinutes % 60)} '
        'and ${_pad2(b.startMinutes ~/ 60)}:${_pad2(b.startMinutes % 60)}).',
      );
    }
    if (conflicts.length > shown) {
      lines.add('… and ${conflicts.length - shown} more conflicts.');
    }
    throw RosterGenerationException(lines.join('\n'));
  }

  /// Advance a `DateTime` by [days] calendar days using the explicit
  /// `DateTime(year, month, day + N, ...)` constructor. This is **not**
  /// equivalent to `base.add(Duration(days: N))`:
  ///
  ///   * `Duration` is wall-clock-time math. Adding `Duration(days: 1)`
  ///     to a DateTime advances by exactly 24 absolute hours. On a DST
  ///     spring-forward day the local-clock representation lands one
  ///     hour late (24h crosses the lost hour), and on a fall-back day
  ///     one hour early.
  ///   * `DateTime(y, m, d + N, ...)` resolves to the local time on the
  ///     target calendar day. Dart's constructor handles month/year
  ///     rollover automatically — `DateTime(2026, 1, 32)` becomes
  ///     `2026-02-01`. Time fields are preserved exactly, so a shift
  ///     scheduled for 07:00 local stays 07:00 local across DST.
  ///
  /// All calendar advancement in this file goes through here for that
  /// reason; the engine derives `fireAt` from `Shift.startDateTime`, so
  /// a 1-hour DST drift here would mis-fire every alarm on the boundary
  /// day.
  static DateTime _addCalendarDays(DateTime base, int days) =>
      DateTime(base.year, base.month, base.day + days);

  /// Field-for-field map from `lib/logic`'s `RotationBlock` to the
  /// persisted `lib/data/models/CycleBlock`. Used to anchor cycles
  /// generated by the pattern path so the resolver can drive the
  /// Calendar UI for any projected day. A near-twin lives in
  /// `lib/ui/onboarding/onboarding_flow.dart`; lift to a shared helper
  /// if a third call site appears.
  static List<CycleBlock> _rotationBlocksToCycleBlocks(
    List<RotationBlock> src,
  ) =>
      List<CycleBlock>.unmodifiable(
        src.map((b) => CycleBlock(
              type: b.type,
              consecutiveDays: b.consecutiveDays,
              startMinutes: b.startMinutes,
              endMinutes: b.endMinutes,
            )),
      );

  /// Folds the custom-builder's positional [ShiftBlock] list into a
  /// sequential [CycleBlock] list the resolver can walk.
  ///
  /// Custom rosters allow same-day split shifts (two blocks covering
  /// the same `cyclePos`), but `CycleBlock` is strictly sequential —
  /// one block per cycle-day position. We resolve that by picking the
  /// first matching block at each position, then merging consecutive
  /// runs of identical (type, startMinutes, endMinutes) into a single
  /// `CycleBlock` so the resolver's `dayWithinBlock`/`consecutiveDays`
  /// reads naturally on the Dashboard ("Day 3 of 4"). Positions with
  /// no block are filled with OFF.
  ///
  /// Loss-of-fidelity: when split shifts exist at the same position,
  /// the Calendar cell only paints the first block's type. The Roster
  /// tab still shows every materialised shift — the data isn't lost,
  /// just the second block's visual representation in the resolver
  /// projection.
  static List<CycleBlock> _foldCustomBlocksToCycleBlocks(
    int cycleLengthDays,
    List<ShiftBlock> blocks,
  ) {
    final merged = <CycleBlock>[];
    for (var p = 0; p < cycleLengthDays; p++) {
      ShiftBlock? hit;
      for (final b in blocks) {
        if (p >= b.startDayIndex && p <= b.endDayIndex) {
          hit = b;
          break;
        }
      }
      final type = hit?.type ?? ShiftType.off;
      final startMin = hit?.startMinutes ?? 0;
      final endMin = hit?.endMinutes ?? 0;
      if (merged.isNotEmpty &&
          merged.last.type == type &&
          merged.last.startMinutes == startMin &&
          merged.last.endMinutes == endMin) {
        merged[merged.length - 1] = merged.last.copyWith(
          consecutiveDays: merged.last.consecutiveDays + 1,
        );
      } else {
        merged.add(CycleBlock(
          type: type,
          consecutiveDays: 1,
          startMinutes: startMin,
          endMinutes: endMin,
        ));
      }
    }
    return List<CycleBlock>.unmodifiable(merged);
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static String _formatTimeRange(int startMinutes, int endMinutes) {
    return '${_pad2(startMinutes ~/ 60)}:${_pad2(startMinutes % 60)} – '
        '${_pad2(endMinutes ~/ 60)}:${_pad2(endMinutes % 60)}';
  }

  // Local copy rather than importing the UI's `shiftTypeLabel` — `lib/logic`
  // must not depend on `lib/ui`. If a third caller needs this, lift to
  // `lib/data/models/shift_type.dart` (the natural home).
  static String _typeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        return 'Off';
    }
  }
}
