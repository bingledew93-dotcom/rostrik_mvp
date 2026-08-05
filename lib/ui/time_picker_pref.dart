import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_preferences.dart';

/// A [showTimePicker] wrapper that remembers the user's preferred entry mode.
///
/// Rostrik historically forced the tap-to-type keyboard
/// ([TimePickerEntryMode.input]) at every call site because field testing
/// showed users disliked dragging the dial hands. But that mode isn't everyone's
/// preference — so now whichever mode the user switches to *inside* the dialog
/// becomes their remembered default (persisted through [AppPreferences]), and
/// every time picker in the app opens the way they last left it.
///
/// A drop-in replacement for `showTimePicker(context:, initialTime:)` — the same
/// picked [TimeOfDay] (or null on cancel) comes back. Purely an entry-mode
/// preference: it never changes the time the user picks or touches any alarm
/// logic. The `listen: false` lookup + null fallback means a widget tree without
/// [AppPreferences] (e.g. a test) simply degrades to the keyboard default.
Future<TimeOfDay?> pickPreferredTime(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  final prefs = Provider.of<AppPreferences?>(context, listen: false);
  final initialMode = (prefs?.timePickerUsesDial ?? false)
      ? TimePickerEntryMode.dial
      : TimePickerEntryMode.input;
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    initialEntryMode: initialMode,
    // Fires whenever the user toggles dial ⇄ keyboard inside the dialog. Persist
    // their choice as the new default so the next picker opens the same way.
    // Only the two user-reachable modes ever arrive here; the `*Only` variants
    // are never passed as [initialEntryMode], so they can't be reported back.
    onEntryModeChanged: (mode) {
      if (mode == TimePickerEntryMode.dial) {
        prefs?.setTimePickerUsesDial(true);
      } else if (mode == TimePickerEntryMode.input) {
        prefs?.setTimePickerUsesDial(false);
      }
    },
  );
}
