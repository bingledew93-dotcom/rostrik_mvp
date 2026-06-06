import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';

/// Transient result of [OcrTimeParser.parse] — a single roster cell decoded
/// into minute-of-day integers.
///
/// Deliberately NOT a Hive entity: it is an in-flight parse product that a
/// later phase converts into a persisted `Shift` / `CycleBlock` once the user
/// confirms the scan. Keeping it pure Dart (no `@HiveType`) also keeps the
/// parser and its tests free of any storage bootstrap.
///
///   * [startMinutes] — always present; minutes since local midnight
///     (0–1439, so 06:00 = 360).
///   * [endMinutes]   — the shift's end, when known. Null for a bare single
///     time (the 24h/12h tiers capture one instant); populated for an
///     explicit range (`0600-1800`) and for the grid-letter blocks (which
///     carry a standard industry start + end).
///   * [type]         — set only by the grid-letter fallback (D/N/A/O →
///     day/night/afternoon/off). Null for parsed times, whose shift type the
///     image does not reveal.
@immutable
class ShiftBlock {
  const ShiftBlock({
    required this.startMinutes,
    this.endMinutes,
    this.type,
  })  : assert(
          startMinutes >= 0 && startMinutes < 1440,
          'startMinutes must be 0..1439',
        ),
        assert(
          endMinutes == null || (endMinutes >= 0 && endMinutes < 1440),
          'endMinutes must be null or 0..1439',
        );

  final int startMinutes;
  final int? endMinutes;
  final ShiftType? type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftBlock &&
          runtimeType == other.runtimeType &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes &&
          type == other.type;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes, type);

  @override
  String toString() =>
      'ShiftBlock(startMinutes: $startMinutes, endMinutes: $endMinutes, '
      'type: $type)';
}
