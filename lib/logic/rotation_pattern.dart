import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';

/// One contiguous run of same-type shifts inside a [RotationPattern].
///
/// Times are stored as minute-of-day (0..1439) — same shape the [Shift]
/// model uses, so expansion in `ShiftGenerator.generateAndPersistPattern`
/// is a direct copy without unit conversion. For [ShiftType.off] blocks,
/// `startMinutes` and `endMinutes` are ignored (the [Shift] still gets
/// 0/0 written, matching how the existing single-shift editor handles
/// off entries — see `shift_editor_modal.dart` line 109).
@immutable
class RotationBlock {
  const RotationBlock({
    required this.type,
    required this.consecutiveDays,
    this.startMinutes = 0,
    this.endMinutes = 0,
  });

  final ShiftType type;
  final int consecutiveDays;
  final int startMinutes;
  final int endMinutes;
}

/// A named rotation cycle: an ordered list of [RotationBlock]s that
/// describe one full repeat of the schedule. The user picks one of these
/// + a start date + a cycle count, and the generator expands it into
/// individual `Shift` records.
///
/// `id` is a stable string handle (used in tests, ListTile keys, and
/// any future "remember last used" persistence). Don't pull it from the
/// label — labels are user-facing copy and may be reworded.
@immutable
class RotationPattern {
  const RotationPattern({
    required this.id,
    required this.label,
    required this.summary,
    required this.blocks,
  });

  final String id;
  final String label;
  final String summary;
  final List<RotationBlock> blocks;

  /// Total days in one full cycle. Drives the live "≈ N days" estimate
  /// in the picker UI: `cycles * cycleDays`.
  int get cycleDays =>
      blocks.fold(0, (n, b) => n + b.consecutiveDays);
}

// Default time windows shared across presets. Centralised so a future
// "shift workers in country X work 06:00–14:00" tweak lands in one place.
// Afternoon constants are intentionally absent until a preset uses them.
const _kDayStart = 7 * 60;    // 07:00
const _kDayEnd = 15 * 60;     // 15:00
const _kNightStart = 22 * 60; // 22:00
const _kNightEnd = 6 * 60;    // 06:00 next day (overnight via Shift.isOvernight)

/// Day Only Swings — every work block is [ShiftType.day] fired at the
/// shared `_kDay*` window. Rendered when the user picks `RosterType.day`
/// on step 3 of onboarding, and as the "Day Only Swings" section of the
/// post-onboarding picker.
///
/// Strict curated list; ordering is the display order. IDs are prefixed
/// `day-` so they can't collide with the night / rotating lists' IDs.
const kDayPatterns = <RotationPattern>[
  RotationPattern(
    id: 'day-14-7',
    label: '14/7',
    summary: '14 Days, 7 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 14,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
    ],
  ),
  RotationPattern(
    id: 'day-7-7',
    label: '7/7',
    summary: '7 Days, 7 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 7,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
    ],
  ),
  RotationPattern(
    id: 'day-8-6',
    label: '8/6',
    summary: '8 Days, 6 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 8,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 6),
    ],
  ),
  RotationPattern(
    id: 'day-5-2',
    label: '5/2',
    summary: '5 Days, 2 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 5,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
    ],
  ),
  RotationPattern(
    id: 'day-5-2-4-3',
    label: '5/2/4/3',
    summary: '5 Days, 2 Off, 4 Days, 3 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 5,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 4,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 3),
    ],
  ),
];

/// Night Only Swings — every work block is [ShiftType.night] fired at
/// the shared `_kNight*` window (22:00 → 06:00 overnight, resolved by
/// `Shift.isOvernight`). Rendered when the user picks `RosterType.night`
/// on step 3 of onboarding, and as the "Night Only Swings" section of
/// the post-onboarding picker.
const kNightPatterns = <RotationPattern>[
  RotationPattern(
    id: 'night-8-6',
    label: '8/6',
    summary: '8 Nights, 6 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 8,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 6),
    ],
  ),
  RotationPattern(
    id: 'night-7-7',
    label: '7/7',
    summary: '7 Nights, 7 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 7,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
    ],
  ),
  RotationPattern(
    id: 'night-4-4',
    label: '4/4',
    summary: '4 Nights, 4 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 4,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 4),
    ],
  ),
  RotationPattern(
    id: 'night-2-2-3',
    label: '2/2/3',
    summary: '2 Nights, 2 Off, 3 Nights, 2 Off, 2 Nights, 3 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 3,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 3),
    ],
  ),
  RotationPattern(
    id: 'night-2-3-2',
    label: '2/3/2',
    summary: '2 Nights, 3 Off, 2 Nights, 2 Off, 3 Nights, 2 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 3),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 3,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
    ],
  ),
];

/// Rotating Swings — mixed-type rotations that alternate between
/// [ShiftType.day] and [ShiftType.night] inside a single cycle.
/// Rendered when the user picks `RosterType.rotating` on step 3 of
/// onboarding, and as the "Rotating Swings" section of the
/// post-onboarding picker.
///
/// Six curated heavy-industry rotations. IDs are prefixed `rot-` so
/// they can't collide with the day / night lists' IDs.
const kRotatingPatterns = <RotationPattern>[
  RotationPattern(
    id: 'rot-14-14',
    label: '14/14',
    summary: '7 Days, 7 Nights, 14 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 7,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 7,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 14),
    ],
  ),
  RotationPattern(
    id: 'rot-14-7',
    label: '14/7',
    summary: '7 Days, 7 Nights, 7 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 7,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 7,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
    ],
  ),
  RotationPattern(
    id: 'rot-7-7-dn',
    label: '7/7 D/N',
    summary: '7 Days, 7 Off, 7 Nights, 7 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 7,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 7,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 7),
    ],
  ),
  RotationPattern(
    id: 'rot-first-responder',
    label: 'First Responder Standard',
    summary: '2 Days, 2 Nights, 4 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 2,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 4),
    ],
  ),
  RotationPattern(
    id: 'rot-4-5-5-4',
    label: '4/5/5/4',
    summary: '4 Days, 5 Off, 5 Nights, 5 Off, 5 Days, 4 Off, 4 Days, 5 Off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 4,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 5),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 5,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 5),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 5,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 4),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 4,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 5),
    ],
  ),
  RotationPattern(
    id: 'rot-2-2-3',
    label: '2/2/3',
    summary:
        '2D / 2off / 3N / 2off / 2D / 3off / 2N / 2off / 3D / 2off / 2D / 3off',
    blocks: [
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 2,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 3,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 2,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 3),
      RotationBlock(
        type: ShiftType.night,
        consecutiveDays: 2,
        startMinutes: _kNightStart,
        endMinutes: _kNightEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 3,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 2),
      RotationBlock(
        type: ShiftType.day,
        consecutiveDays: 2,
        startMinutes: _kDayStart,
        endMinutes: _kDayEnd,
      ),
      RotationBlock(type: ShiftType.off, consecutiveDays: 3),
    ],
  ),
];

/// Flat concatenation of every preset across the three category lists.
/// Used by the post-onboarding pattern picker (which has no upfront
/// roster-type gate) and by the integrity tests that want to assert
/// invariants across the whole curated set.
const kAllPatterns = <RotationPattern>[
  ...kDayPatterns,
  ...kNightPatterns,
  ...kRotatingPatterns,
];
