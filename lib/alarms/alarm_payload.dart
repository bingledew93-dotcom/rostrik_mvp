import 'alarm_sound.dart';

/// Pure codec for the notification payload string — the one wire format that
/// crosses every alarm boundary: the scheduler that creates it, both
/// notification-action paths (foreground dispatcher AND the killed-app
/// background isolate), and the cold-launch wake route.
///
/// This is the single source of truth that replaces the formerly-duplicated
/// private `_parsePayload` helpers in `notification_action_dispatcher.dart`,
/// `notification_response_handler.dart`, and `main.dart`. It deliberately
/// imports nothing but [AlarmSound] (for the default key), so it is free of the
/// scheduler↔dispatcher import cycle that motivated the original duplication —
/// every layer can import it without coupling.
///
/// **Wire format** (pipe-delimited, positional — `|` therefore cannot appear
/// in any field; tone keys, UUIDs and the `NONE` sentinel are `|`-free by
/// design):
///
/// ```
///   <shiftId>|<notificationId>|<dismissCode>|<soundKey>|<appAlarmId>|<ringtone>|<vibrate>
///      0  shiftId        Shift UUID, or the `NONE` sentinel for an alarm with
///                        no linked shift (oneTime / weekly).
///      1  notificationId OS notification id (int).
///      2  dismissCode    'c' = critical-shift wake mechanics (shake + hold);
///                        'n' = normal slide-to-dismiss.
///      3  soundKey       bundled-tone key — see [AlarmSound.key].
///      4  appAlarmId     owning [AppAlarm] UUID, or '' when unknown. Lets the
///                        dismiss handlers find the rule that fired so an
///                        auto-delete one-time alarm can be removed at the
///                        dismissal instant — even from a killed state, where
///                        the notification id alone can't be reversed to a rule.
///      5  ringtone       durable path / `content://` URI of the global custom
///                        ringtone, or '' for the bundled default. Non-empty ⇒
///                        the alarm was scheduled on the SILENT channel and
///                        WakeUpScreen plays this tone via the native player.
///      6  vibrate        '1' = vibrate, '0' = silent. Drives the continuous
///                        native haptic loop for custom-ringtone alarms.
/// ```
///
/// **Backward-tolerant decode.** A 2-, 3-, 4-, 5- or 6-field payload still
/// decodes: any missing tail field is defaulted (`isCritical = false`,
/// `soundKey = kDefaultAlarmSoundKey`, `appAlarmId = ''`,
/// `customRingtoneUri = null`, `vibrationEnabled = true`). This matters for live
/// cases like:
///   * OS-pending notifications scheduled by an older build (pre-sound /
///     pre-critical / pre-appAlarmId / pre-ringtone / pre-vibrate) that fire
///     after an update,
///   * `WakeUpScreen`'s in-app Snooze, which reconstructs a bare
///     `shiftId|notificationId` string, and
///   * any shorter payload from a build immediately before a field landed.
/// In all of them, the next `AlarmSyncService` reconcile re-issues the full
/// 7-field form, so the degradation is momentary.
class AlarmPayload {
  const AlarmPayload({
    required this.shiftId,
    required this.notificationId,
    required this.isCritical,
    required this.soundKey,
    this.appAlarmId = '',
    this.customRingtoneUri,
    this.vibrationEnabled = true,
  });

  final String shiftId;
  final int notificationId;
  final bool isCritical;
  final String soundKey;

  /// Owning [AppAlarm] UUID, or '' when the payload predates this field (or was
  /// reconstructed without it). Callers treat '' as "no identity available" and
  /// skip the auto-delete path rather than guessing.
  final String appAlarmId;

  /// Durable path of the user's global custom ringtone (from
  /// `AlarmSettings.customRingtoneUri`), or null on the bundled default. This
  /// rides the payload as FORWARD-PLUMBING for the deferred native playback
  /// path — nothing consumes it yet; the OS still owns alarm audio via the
  /// per-tone notification channel. The path is sanitised at write time to be
  /// `|`-free (see the create-sheet's ringtone persist step).
  final String? customRingtoneUri;

  /// Whether the firing alarm vibrates (field 6). Defaults to true (absent on
  /// pre-vibrate payloads). Read by `WakeUpScreen` and passed to the native
  /// haptic engine alongside the custom tone.
  final bool vibrationEnabled;

  /// Field-2 code for critical-shift wake mechanics.
  static const String _criticalCode = 'c';

  /// Field-2 code for the normal slide-to-dismiss.
  static const String _normalCode = 'n';

  /// Builds the canonical 7-field payload string. [customRingtoneUri] is
  /// emitted as an empty trailing field when null (the common, bundled-default
  /// case); [vibrationEnabled] is emitted as '1' / '0'. Both are read back by
  /// the backward-tolerant [decode] (absent ⇒ null / true respectively).
  static String encode({
    required String shiftId,
    required int notificationId,
    required bool isCritical,
    required String soundKey,
    required String appAlarmId,
    required String? customRingtoneUri,
    required bool vibrationEnabled,
  }) =>
      '$shiftId|$notificationId|'
      '${isCritical ? _criticalCode : _normalCode}|$soundKey|$appAlarmId|'
      '${customRingtoneUri ?? ''}|${vibrationEnabled ? '1' : '0'}';

  /// Parses [payload] into an [AlarmPayload], or `null` if it is missing,
  /// empty, has an empty shiftId, or carries a non-int notificationId — all of
  /// which callers treat as a no-op rather than throwing (a thrown exception in
  /// a background isolate is a silent, user-invisible failure).
  static AlarmPayload? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split('|');
    if (parts.length < 2 || parts[0].isEmpty) return null;

    final notificationId = int.tryParse(parts[1]);
    if (notificationId == null) return null;

    final isCritical = parts.length > 2 && parts[2] == _criticalCode;
    final soundKey = (parts.length > 3 && parts[3].isNotEmpty)
        ? parts[3]
        : kDefaultAlarmSoundKey;
    final appAlarmId = parts.length > 4 ? parts[4] : '';
    // Field 5 (custom ringtone) — empty or absent ⇒ null (bundled default).
    final customRingtoneUri = (parts.length > 5 && parts[5].isNotEmpty)
        ? parts[5]
        : null;
    // Field 6 (vibrate) — absent ⇒ true (historical always-vibrate default);
    // only an explicit '0' turns it off.
    final vibrationEnabled = parts.length > 6 ? parts[6] != '0' : true;

    return AlarmPayload(
      shiftId: parts[0],
      notificationId: notificationId,
      isCritical: isCritical,
      soundKey: soundKey,
      appAlarmId: appAlarmId,
      customRingtoneUri: customRingtoneUri,
      vibrationEnabled: vibrationEnabled,
    );
  }
}
