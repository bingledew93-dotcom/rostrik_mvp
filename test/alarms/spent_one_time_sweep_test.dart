import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/spent_one_time_sweep.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

void main() {
  // Mon 2026-06-15, 09:00.
  final now = DateTime(2026, 6, 15, 9, 0);

  AppAlarm alarm({
    String id = 'a1',
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.oneTime,
    DateTime? anchor,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 6 * 60,
        label: 'One-off',
        repeatType: repeatType,
        linkedShiftType: repeatType == AppAlarmRepeatType.followsRotation
            ? ShiftType.day
            : null,
        oneTimeFireAt: anchor,
      );

  Future<FakeAppAlarmRepository> repoWith(List<AppAlarm> alarms) async {
    final repo = FakeAppAlarmRepository();
    for (final a in alarms) {
      await repo.upsert(a);
    }
    return repo;
  }

  test('deletes a one-time alarm whose anchor has passed', () async {
    final repo = await repoWith([
      alarm(anchor: DateTime(2026, 6, 15, 6, 0)), // rang 3h ago
    ]);
    addTearDown(repo.dispose);

    expect(await sweepSpentOneTimeAlarms(repo, now: now), 1);
    expect(await repo.getAll(), isEmpty);
  });

  test('leaves a one-time alarm whose anchor is still ahead', () async {
    final repo = await repoWith([
      alarm(anchor: DateTime(2026, 6, 16, 6, 0)), // tomorrow
    ]);
    addTearDown(repo.dispose);

    expect(await sweepSpentOneTimeAlarms(repo, now: now), 0);
    expect(await repo.getAll(), hasLength(1));
  });

  // Legacy records predate the anchor. Their intended date cannot be
  // reconstructed, and deleting an alarm the user may still rely on is the
  // worse failure — so they are left to the old rolling behaviour.
  test('never touches a legacy alarm with no anchor', () async {
    final repo = await repoWith([alarm()]);
    addTearDown(repo.dispose);

    expect(await sweepSpentOneTimeAlarms(repo, now: now), 0);
    expect(await repo.getAll(), hasLength(1));
  });

  test('never touches recurring alarms, whatever their anchor', () async {
    final repo = await repoWith([
      alarm(
        id: 'w',
        repeatType: AppAlarmRepeatType.weekly,
        anchor: DateTime(2026, 6, 15, 6, 0),
      ),
      alarm(
        id: 'r',
        repeatType: AppAlarmRepeatType.followsRotation,
        anchor: DateTime(2026, 6, 15, 6, 0),
      ),
    ]);
    addTearDown(repo.dispose);

    expect(await sweepSpentOneTimeAlarms(repo, now: now), 0);
    expect(await repo.getAll(), hasLength(2));
  });

  // A snoozed one-time alarm's anchor is ALWAYS in the past — the snooze exists
  // precisely because it fired. Retiring on the anchor alone would delete the
  // rule out from under a live snooze and the user would never be woken.
  test('does not delete a spent alarm with a snooze still pending', () async {
    final repo = await repoWith([
      alarm(anchor: DateTime(2026, 6, 15, 6, 0)),
    ]);
    addTearDown(repo.dispose);

    final swept = await sweepSpentOneTimeAlarms(
      repo,
      now: now,
      oneOffSnoozes: {'a1': DateTime(2026, 6, 15, 9, 9)}, // 9 min out
    );
    expect(swept, 0);
    expect(await repo.getAll(), hasLength(1));
  });

  test('deletes once the snooze itself has elapsed', () async {
    final repo = await repoWith([
      alarm(anchor: DateTime(2026, 6, 15, 6, 0)),
    ]);
    addTearDown(repo.dispose);

    final swept = await sweepSpentOneTimeAlarms(
      repo,
      now: now,
      oneOffSnoozes: {'a1': DateTime(2026, 6, 15, 8, 30)}, // already passed
    );
    expect(swept, 1);
    expect(await repo.getAll(), isEmpty);
  });

  test('is idempotent — a second pass finds nothing', () async {
    final repo = await repoWith([
      alarm(anchor: DateTime(2026, 6, 15, 6, 0)),
    ]);
    addTearDown(repo.dispose);

    expect(await sweepSpentOneTimeAlarms(repo, now: now), 1);
    expect(await sweepSpentOneTimeAlarms(repo, now: now), 0);
  });
}
