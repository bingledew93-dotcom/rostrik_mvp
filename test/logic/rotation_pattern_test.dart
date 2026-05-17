import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/rotation_pattern.dart';

void main() {
  group('RotationPattern.cycleDays', () {
    test('sums consecutiveDays across blocks', () {
      const pattern = RotationPattern(
        id: 'x',
        label: 'X',
        summary: 'x',
        blocks: [
          RotationBlock(type: ShiftType.day, consecutiveDays: 3),
          RotationBlock(type: ShiftType.off, consecutiveDays: 2),
        ],
      );
      expect(pattern.cycleDays, 5);
    });

    test('zero blocks ⇒ zero days (defensive, not a real preset shape)', () {
      const pattern = RotationPattern(
        id: 'x',
        label: 'X',
        summary: 'x',
        blocks: [],
      );
      expect(pattern.cycleDays, 0);
    });
  });

  group('kAllPatterns — preset list integrity', () {
    test('every preset has a non-empty id, label, and summary', () {
      // Cheap regression guard: a copy-paste preset that forgets to
      // change the id/label is a real, plausible mistake; this catches
      // it the moment it lands.
      for (final p in kAllPatterns) {
        expect(p.id, isNotEmpty, reason: '$p.id must be non-empty');
        expect(p.label, isNotEmpty, reason: '${p.id} label must be non-empty');
        expect(
          p.summary,
          isNotEmpty,
          reason: '${p.id} summary must be non-empty',
        );
      }
    });

    test('preset IDs are unique across the list', () {
      final ids = kAllPatterns.map((p) => p.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'duplicate id in kAllPatterns: $ids',
      );
    });

    test('every preset has at least one block', () {
      // A zero-block preset would render in the UI, take a slot, but
      // generate nothing on Save — silent UX failure.
      for (final p in kAllPatterns) {
        expect(
          p.blocks,
          isNotEmpty,
          reason: '${p.id} must have at least one block',
        );
      }
    });

    test('every preset cycle is at least 2 days long', () {
      // A "rotation" of 1 day isn't a rotation. This pins the design
      // intent of the list: presets describe multi-day cycles, not
      // single-shift conveniences (the editor handles those).
      for (final p in kAllPatterns) {
        expect(
          p.cycleDays,
          greaterThanOrEqualTo(2),
          reason: '${p.id} cycle is ${p.cycleDays} days — too short',
        );
      }
    });

    test('every non-OFF block has a non-zero-duration time window', () {
      // Day/Night/Afternoon blocks need real start/end times; the
      // generator persists 0/0 for OFF and the time-bearing types
      // require a window the engine can compute fireAt against.
      for (final p in kAllPatterns) {
        for (final b in p.blocks) {
          if (b.type == ShiftType.off) continue;
          expect(
            b.startMinutes,
            isNot(equals(b.endMinutes)),
            reason: '${p.id} ${b.type} block has zero-duration window',
          );
        }
      }
    });

    test('every OFF block has zero start/end (per the data convention)', () {
      // Convention: OFF shifts persist 0/0 — matches what the existing
      // single-shift editor writes. Pinning this means a future
      // accidental "OFF block with times" preset doesn't slip through.
      for (final p in kAllPatterns) {
        for (final b in p.blocks) {
          if (b.type != ShiftType.off) continue;
          expect(b.startMinutes, 0);
          expect(b.endMinutes, 0);
        }
      }
    });
  });

  group('RotationBlock defaults', () {
    test('startMinutes/endMinutes default to 0 (off-friendly)', () {
      // Critical because OFF presets construct RotationBlock without
      // naming start/end; if the defaults regress to "required", the
      // const list above stops compiling.
      const block = RotationBlock(type: ShiftType.off, consecutiveDays: 7);
      expect(block.startMinutes, 0);
      expect(block.endMinutes, 0);
    });
  });
}
