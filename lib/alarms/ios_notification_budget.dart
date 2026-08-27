/// How Rostrik spends iOS's fixed notification allowance.
///
/// iOS keeps at most **64 pending notifications per app** and silently drops
/// the rest — there is no error, the alarm simply never arrives. Every surface
/// draws on the same pool: shift alarms, their repeat chains, sleep nudges and
/// activity reminders. The arithmetic therefore has to live in one place rather
/// than being rediscovered per feature.
///
/// ## Why alarms need a repeat chain at all
///
/// An iOS notification sound stops after ~30s (the tones are pre-looped to fill
/// that ceiling — see `ios/tools/generate_alarm_tones.sh`). Android rings until
/// dismissed, because it owns a foreground audio service for the alarm's
/// duration; iOS runs no app code at all when a notification fires. A single
/// alert is simply not an alarm for a heavy sleeper, which is the exact user
/// this app exists for.
///
/// The fix is to queue follow-up notifications after the alarm and cancel them
/// the moment the user responds — [kAlarmRepeatChainLength] of them, spaced
/// [kAlarmRepeatInterval] apart.
///
/// ## The trade-off this encodes
///
/// Chains are expensive, so only the [kChainedAlarmCount] most imminent alarms
/// get one, and the iOS alarm cap drops to [kIosMaxScheduledAlarms] to pay for
/// them. That shortens how far ahead alarms are pre-armed on iOS — but the
/// reconcile re-arms on every app open and every background refresh, whereas an
/// alarm that rings for 28 seconds and gives up cannot be recovered from at all.
/// Waking the user beats pre-arming further out.
library;

/// iOS's hard ceiling on pending notifications per app.
const int kIosNotificationCeiling = 64;

/// Held back for the non-alarm surfaces that share the pool: the two sleep
/// nudges, the trial-expiry nudge, and per-activity reminders.
const int kIosReminderReserve = 12;

/// How many of the most imminent alarms get a repeat chain. Only the next few
/// matter — the reconcile moves the chain forward as they fire, and dismissing
/// one triggers a resync that re-chains the next.
const int kChainedAlarmCount = 2;

/// Follow-up alerts queued after a chained alarm.
const int kAlarmRepeatChainLength = 8;

/// Spacing between them. Matched to the ~30s sound cap so the alerts run
/// close to back-to-back rather than leaving long silences.
const Duration kAlarmRepeatInterval = Duration(seconds: 30);

/// Total notifications a chained alarm consumes: the alarm itself plus its
/// follow-ups.
const int kChainCost = kChainedAlarmCount * kAlarmRepeatChainLength;

/// The iOS alarm cap, derived so the worst case stays under the ceiling:
///
///     32 alarms + 16 chain alerts + 12 reserved = 60, against a ceiling of 64.
///
/// Android keeps the larger cap — it has no such ceiling and no chains.
const int kIosMaxScheduledAlarms =
    kIosNotificationCeiling - kIosReminderReserve - kChainCost - 4;
