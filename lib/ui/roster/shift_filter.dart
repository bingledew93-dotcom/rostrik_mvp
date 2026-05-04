import 'package:flutter/material.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';

/// Display-time filter for the roster views. UI-only concept — does not
/// touch persistence and does not belong in the data layer.
///
/// The enum is designed to grow: adding new categories (events, leave,
/// …) is a matter of adding new values + extending [matches] and [label].
/// Both `switch` expressions below are exhaustive, so the analyzer will
/// flag every unhandled case the day a new enum value is added.
enum ShiftFilter {
  all,
  work,
  off;

  String get label => switch (this) {
        ShiftFilter.all => 'All',
        ShiftFilter.work => 'Work',
        ShiftFilter.off => 'Off',
      };

  /// Whether [shift] should be visible under this filter. The orchestrator
  /// uses [apply] in the hot path; [matches] is exposed because tests and
  /// future cell builders may want a single-shift predicate.
  bool matches(Shift shift) => switch (this) {
        ShiftFilter.all => true,
        ShiftFilter.work => shift.type == ShiftType.day ||
            shift.type == ShiftType.afternoon ||
            shift.type == ShiftType.night,
        ShiftFilter.off => shift.type == ShiftType.off,
      };

  /// Returns the subset of [shifts] this filter admits, preserving order.
  /// Short-circuits on [ShiftFilter.all] — returns the input list unchanged
  /// to avoid an allocation when the user has no filter active.
  List<Shift> apply(List<Shift> shifts) =>
      this == ShiftFilter.all ? shifts : shifts.where(matches).toList();
}

/// Horizontal strip of single-select chips. Single-select because "All"
/// doesn't compose with "Work"/"Off" — it's a different category of
/// filter. ChoiceChip is the M3 idiom for this.
///
/// The strip scrolls horizontally so adding more chips later (Events,
/// Leave) doesn't force a layout rework on smaller screens.
class ShiftFilterChips extends StatelessWidget {
  const ShiftFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ShiftFilter value;
  final ValueChanged<ShiftFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ShiftFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = ShiftFilter.values[i];
          return Center(
            child: ChoiceChip(
              label: Text(f.label),
              selected: value == f,
              onSelected: (selected) {
                // Tapping the already-selected chip is a no-op rather than
                // deselecting back to nothing — the screen always has a
                // filter active (default = all).
                if (selected) onChanged(f);
              },
            ),
          );
        },
      ),
    );
  }
}
