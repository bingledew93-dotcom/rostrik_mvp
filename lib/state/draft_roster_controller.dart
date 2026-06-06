import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';
import '../logic/rotation_pattern_validator.dart' show RosterGenerationException;
import '../logic/shift_block.dart';
import '../logic/shift_generator.dart';
import '../ocr/roster_injection.dart';

/// One reviewable day in the draft — the view-model a single review row binds
/// to. Immutable; rebuilt from the controller's internal entries on every read.
///
///   * [id]   — stable across edits so a list can key its rows (and animate a
///     swipe-delete) without the index-reuse bugs `Dismissible` is prone to.
///   * [date] — derived as `anchor + position`, NOT stored. Deleting a row
///     re-compacts the sequence, so the day that followed a deleted phantom
///     correctly slides back onto the right calendar date.
///   * [needsEndTime] — the same flag the builder uses ([ScannedRosterInjection.
///     needsEndTime]): a non-Off block still sitting at the zero-duration
///     placeholder a bare scanned time produces.
@immutable
class DraftDay {
  const DraftDay({
    required this.id,
    required this.date,
    required this.block,
    required this.needsEndTime,
  });

  final int id;
  final DateTime date;
  final ShiftBlock block;
  final bool needsEndTime;
}

/// A day pulled out of the draft by [DraftRosterController.removeAt], returned
/// so the UI can offer Undo (re-insert at [index]) before the change is final.
@immutable
class RemovedDay {
  const RemovedDay({required this.index, required this.block});

  final int index;
  final ShiftBlock block;
}

/// Holds the **entire** in-memory draft of a scanned roster while the user
/// reviews it, and is the single owner of the commit-to-Hive step.
///
/// Lifecycle: constructed from the freshly scanned + mapped blocks, mutated by
/// the review UI (delete / re-type / set end time), and persisted exactly once
/// when [commit] succeeds. Nothing here touches storage until then — the draft
/// is pure memory, which is what makes "discard by backing out" free and the
/// whole class unit-testable with a fake [ShiftGenerator].
///
/// Business logic only: it imports no Flutter widgets. The screen binds to it
/// through `ChangeNotifierProvider` and reads [days] / [canCommit] / etc.,
/// keeping every roster decision out of the widget tree.
class DraftRosterController extends ChangeNotifier {
  DraftRosterController({
    required ShiftGenerator generator,
    required DateTime anchorDate,
    required List<ShiftBlock> initialBlocks,
    Uint8List? sourceImage,
    String label = 'Scanned roster',
  })  : _generator = generator,
        _anchorDate =
            DateTime(anchorDate.year, anchorDate.month, anchorDate.day),
        _sourceImage = sourceImage,
        _label = label,
        _entries = [
          for (final b in initialBlocks) _Entry(_nextId++, b),
        ];

  final ShiftGenerator _generator;
  final DateTime _anchorDate;
  final Uint8List? _sourceImage;
  final List<_Entry> _entries;

  String _label;
  bool _isCommitting = false;
  String? _commitError;

  // Monotonic source of stable row ids. Static so re-inserts (Undo) and fresh
  // controllers never collide within a session; the value itself is opaque.
  static int _nextId = 0;

  /// Local-midnight start date the whole sequence is laid out from.
  DateTime get anchorDate => _anchorDate;

  /// Cropped scan bytes for the on-screen reference panel, or null if the
  /// caller didn't capture one. Compressed JPEG — decode at display size.
  Uint8List? get sourceImage => _sourceImage;

  String get label => _label;
  bool get isCommitting => _isCommitting;

  /// The generator's rejection message after a failed [commit] (e.g. a
  /// time-overlap report), or null. Cleared by any subsequent edit.
  String? get commitError => _commitError;

  bool get isEmpty => _entries.isEmpty;
  int get dayCount => _entries.length;

  /// The reviewable rows, one per draft day, dated from the anchor.
  List<DraftDay> get days => [
        for (var i = 0; i < _entries.length; i++)
          DraftDay(
            id: _entries[i].id,
            date: DateTime(
              _anchorDate.year,
              _anchorDate.month,
              _anchorDate.day + i,
            ),
            block: _entries[i].block,
            needsEndTime:
                ScannedRosterInjection.needsEndTime(_entries[i].block),
          ),
      ];

  /// How many rows still need an end time — drives the "finish this" banner.
  int get attentionCount =>
      _entries.where((e) => ScannedRosterInjection.needsEndTime(e.block)).length;

  /// True when the draft is ready to persist: not mid-commit, at least one
  /// day, and nothing still missing an end time. The generator runs its own
  /// structural + overlap validation on top; this is the cheap up-front gate.
  bool get canCommit => !_isCommitting && _entries.isNotEmpty && attentionCount == 0;

  /// Sets the roster name. Deliberately does NOT notify: the screen owns the
  /// `TextField` and notifying mid-keystroke would fight the cursor. The value
  /// is only read at [commit].
  void setLabel(String value) => _label = value;

  /// Removes the day at [index] and returns it so the caller can offer Undo.
  /// Positions after it shift up by one — re-dating the remaining scanned days
  /// correctly (a phantom never owned a real calendar day).
  RemovedDay removeAt(int index) {
    final removed = _entries.removeAt(index);
    _commitError = null;
    notifyListeners();
    return RemovedDay(index: index, block: removed.block);
  }

  /// Re-inserts a previously removed day (the Undo of [removeAt]).
  void insertAt(int index, ShiftBlock block) {
    _entries.insert(index.clamp(0, _entries.length), _Entry(_nextId++, block));
    _commitError = null;
    notifyListeners();
  }

  /// Reassigns the shift type of the row at [index].
  ///
  ///   * → Off: clears the times to 0/0 (Off carries no range).
  ///   * Off → working: seeds the type's standard band so the row is valid
  ///     immediately rather than instantly flagged for an end time.
  ///   * working → working: keeps the scanned/edited times; only the label
  ///     changes — so a bare scanned time stays flagged until the user sets
  ///     its real end.
  void setType(int index, ShiftType type) {
    final b = _entries[index].block;
    if (type == ShiftType.off) {
      _entries[index].block =
          b.copyWith(type: ShiftType.off, startMinutes: 0, endMinutes: 0);
    } else if (b.type == ShiftType.off) {
      final (start, end) = _defaultBand(type);
      _entries[index].block =
          b.copyWith(type: type, startMinutes: start, endMinutes: end);
    } else {
      _entries[index].block = b.copyWith(type: type);
    }
    _commitError = null;
    notifyListeners();
  }

  void setStartMinutes(int index, int minutesOfDay) {
    _entries[index].block =
        _entries[index].block.copyWith(startMinutes: minutesOfDay);
    _commitError = null;
    notifyListeners();
  }

  void setEndMinutes(int index, int minutesOfDay) {
    _entries[index].block =
        _entries[index].block.copyWith(endMinutes: minutesOfDay);
    _commitError = null;
    notifyListeners();
  }

  /// Materialises the draft into the local database via the custom-roster path
  /// (`repeatCount: 1` — a scanned roster is a literal sequence anchored at
  /// [anchorDate], not a repeating cycle). Returns true on success.
  ///
  /// On a [RosterGenerationException] (structural error or time overlap) it
  /// surfaces the message via [commitError] and returns false WITHOUT writing —
  /// the generator throws before any persistence, so a rejected save leaves
  /// the box untouched.
  Future<bool> commit() async {
    if (!canCommit) return false;
    _isCommitting = true;
    _commitError = null;
    notifyListeners();
    try {
      await _generator.generateAndPersistCustom(
        label: _label.trim().isEmpty ? 'Scanned roster' : _label.trim(),
        startDate: _anchorDate,
        cycleLengthDays: _entries.length,
        repeatCount: 1,
        blocks: List<ShiftBlock>.unmodifiable(_normalisedBlocks()),
      );
      _isCommitting = false;
      notifyListeners();
      return true;
    } on RosterGenerationException catch (e) {
      _isCommitting = false;
      _commitError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isCommitting = false;
      _commitError = 'Save failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Re-stamps each block's day index to its current list position, so the
  /// generator lays the sequence on consecutive dates from the anchor with no
  /// gaps — mid-review deletes can otherwise leave the stored indices
  /// non-contiguous.
  List<ShiftBlock> _normalisedBlocks() => [
        for (var i = 0; i < _entries.length; i++)
          _entries[i].block.copyWith(startDayIndex: i, endDayIndex: i),
      ];

  /// Standard industry bands, matching `OcrTimeParser`'s grid-letter fallback
  /// so a re-typed row reads the same as a scanned letter cell would.
  static (int start, int end) _defaultBand(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return (6 * 60, 18 * 60);
      case ShiftType.afternoon:
        return (14 * 60, 22 * 60);
      case ShiftType.night:
        return (18 * 60, 6 * 60);
      case ShiftType.off:
        return (0, 0);
    }
  }
}

/// Internal draft cell: a stable [id] paired with a mutable [block]. Private so
/// the id-stability contract can't be bypassed from outside.
class _Entry {
  _Entry(this.id, this.block);

  final int id;
  ShiftBlock block;
}
