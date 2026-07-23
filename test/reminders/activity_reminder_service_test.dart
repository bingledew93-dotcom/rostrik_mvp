import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/reminders/activity_reminder_service.dart';
import 'package:rostrik_mvp/reminders/reminder_id.dart';

import '../alarms/fakes.dart' show FrozenClock;
import 'fakes.dart';

void main() {
  late FakeCalendarActivityRepository repo;
  late FakeActivityReminderScheduler scheduler;
  late FrozenClock clock;
  late ActivityReminderService service;

  final now = DateTime(2026, 7, 23, 8, 0);

  setUp(() {
    repo = FakeCalendarActivityRepository();
    scheduler = FakeActivityReminderScheduler();
    clock = FrozenClock(now);
    service = ActivityReminderService(
      activities: repo,
      scheduler: scheduler,
      clock: clock,
    );
  });

  tearDown(() async {
    await service.stop();
    await repo.dispose();
  });

  CalendarActivity activity({
    required String id,
    ActivityKind kind = ActivityKind.event,
    int? timeMinutes,
    DateTime? reminderAt,
    String title = 'Thing',
  }) =>
      CalendarActivity(
        id: id,
        date: DateTime(2026, 7, 24),
        title: title,
        kind: kind,
        timeMinutes: timeMinutes,
        reminderAt: reminderAt,
      );

  group('reconcile', () {
    test('schedules a reminder for a future reminderAt', () async {
      final a = activity(
        id: 'a1',
        timeMinutes: 9 * 60,
        reminderAt: DateTime(2026, 7, 24, 8, 30),
      );
      await service.reconcile([a]);

      final id = reminderNotificationId('a1');
      expect(scheduler.scheduled.keys, contains(id));
      expect(scheduler.scheduled[id]!.at, DateTime(2026, 7, 24, 8, 30));
      expect(scheduler.scheduled[id]!.title, 'Thing');
    });

    test('does NOT schedule when reminderAt is null', () async {
      await service.reconcile([activity(id: 'a1')]);
      expect(scheduler.scheduled, isEmpty);
    });

    test('does NOT schedule a reminder in the past', () async {
      await service.reconcile([
        activity(id: 'a1', reminderAt: now.subtract(const Duration(hours: 1))),
      ]);
      expect(scheduler.scheduled, isEmpty);
    });

    test('cancels a reminder when it is cleared on the same activity', () async {
      final a = activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 8, 30));
      await service.reconcile([a]);
      expect(scheduler.scheduled, isNotEmpty);

      // Same activity, reminder cleared → the previously-armed reminder is
      // cancelled.
      await service.reconcile([activity(id: 'a1')]);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.callLog, contains('cancel:${reminderNotificationId('a1')}'));
    });

    test('cancels a reminder when the activity is gone', () async {
      await service
          .reconcile([activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 9))]);
      expect(scheduler.scheduled, isNotEmpty);

      await service.reconcile(const []);
      expect(scheduler.scheduled, isEmpty);
    });

    test('is idempotent — an unchanged snapshot issues no new calls', () async {
      final a = activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 9));
      await service.reconcile([a]);
      scheduler.clearLog();

      await service.reconcile([a]);
      expect(scheduler.callLog, isEmpty);
    });

    test('re-schedules (replace) when the reminder time changes', () async {
      await service
          .reconcile([activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 9))]);
      scheduler.clearLog();

      await service.reconcile(
          [activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 10))]);
      final id = reminderNotificationId('a1');
      expect(scheduler.callLog, contains('schedule:$id'));
      expect(scheduler.scheduled[id]!.at, DateTime(2026, 7, 24, 10));
    });

    test('body reads "<Kind> at <time>" for a timed activity', () async {
      await service.reconcile([
        activity(
          id: 'a1',
          kind: ActivityKind.event,
          timeMinutes: 14 * 60 + 30,
          reminderAt: DateTime(2026, 7, 24, 14),
        ),
      ]);
      expect(scheduler.scheduled.values.single.body, 'Event at 2:30 PM');
    });

    test('body reads the bare kind for an all-day activity', () async {
      await service.reconcile([
        activity(
          id: 'a1',
          kind: ActivityKind.birthday,
          reminderAt: DateTime(2026, 7, 24, 9),
        ),
      ]);
      expect(scheduler.scheduled.values.single.body, 'Birthday');
    });
  });

  group('start', () {
    test('reconciles off the activity stream on subscribe and on change',
        () async {
      await repo.upsert(
        activity(id: 'a1', reminderAt: DateTime(2026, 7, 24, 9)),
      );
      await service.start();
      // Let the stream deliver the initial snapshot.
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.scheduled, isNotEmpty);

      // Deleting the activity trips the stream → the reminder is cancelled.
      await repo.delete('a1');
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.scheduled, isEmpty);
    });
  });
}
