import 'package:flutter/material.dart';

import '../../data/models/shift_type.dart';

/// Visual tokens for a shift type — colour + icon. Centralised so the
/// timeline cards and the calendar grid render the same shift type the
/// same way; if a colour is tweaked, both views move together.
class TypeVisual {
  const TypeVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

TypeVisual visualFor(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return const TypeVisual(
        icon: Icons.wb_sunny_outlined,
        color: Colors.amber,
      );
    case ShiftType.afternoon:
      return const TypeVisual(
        icon: Icons.wb_twilight_outlined,
        color: Colors.orange,
      );
    case ShiftType.night:
      return const TypeVisual(
        icon: Icons.nightlight_outlined,
        color: Colors.indigo,
      );
    case ShiftType.off:
      return const TypeVisual(
        icon: Icons.do_not_disturb_on_outlined,
        color: Colors.grey,
      );
  }
}

/// Compact label for use inside narrow surfaces (calendar cells, badges).
/// Distinct from `shiftTypeLabel` (used in the timeline rows) which can
/// afford full words like "Afternoon".
String shiftTypeShortLabel(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return 'Day';
    case ShiftType.afternoon:
      return 'Aft';
    case ShiftType.night:
      return 'Night';
    case ShiftType.off:
      return 'Off';
  }
}
