import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/logic/work_history.dart';
import 'package:rostrik_mvp/ui/work_history_screen.dart';

import '../alarms/fakes.dart';

void main() {
  // Dates well clear of the real wall clock so the completed/future split is
  // deterministic whenever the suite runs.
  final completed = DateTime(2020, 1, 1); // Wed, Jan 1 2020
  final future = DateTime(2999, 1, 1);

  Shift adhoc({
    required String id,
    required DateTime date,
    int start = 7 * 60,
    int end = 15 * 60,
    ShiftType type = ShiftType.day,
    bool isAdHoc = true,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
        isAdHoc: isAdHoc,
      );

  Future<FakeShiftRepository> pump(
    WidgetTester tester, {
    required List<Shift> seed,
    WorkHistoryExporter? exporter,
  }) async {
    final repo = FakeShiftRepository();
    addTearDown(repo.dispose);
    for (final s in seed) {
      await repo.upsert(s);
    }
    await tester.pumpWidget(
      Provider<ShiftRepository>.value(
        value: repo,
        child: MaterialApp(home: WorkHistoryScreen(exporter: exporter)),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('lists ALL completed shifts (rotation + ad-hoc) with type badges',
      (tester) async {
    await pump(tester, seed: [
      adhoc(id: 'done', date: completed), // ✓ completed ad-hoc, 8.00h
      adhoc(id: 'rota', date: DateTime(2019, 1, 1), isAdHoc: false), // ✓ rotation, 8.00h
      adhoc(id: 'future', date: future), // ✗ not finished
      adhoc(id: 'off', date: DateTime(2020, 2, 1), type: ShiftType.off, start: 0, end: 0), // ✗ off
    ]);

    // Two qualifying shifts (ad-hoc + rotation); OFF + future excluded.
    expect(find.text('2 shifts worked'), findsOneWidget);
    // Summary shows the combined total; each tile shows its own 8.00 h.
    expect(find.text('16.00 h'), findsOneWidget);
    expect(find.text('8.00 h'), findsNWidgets(2));
    // Both dates render…
    expect(find.text('Wed, Jan 1'), findsOneWidget); // 2020-01-01 (ad-hoc)
    expect(find.text('Tue, Jan 1'), findsOneWidget); // 2019-01-01 (rotation)
    // …each with its provenance badge.
    expect(find.text('Ad-Hoc'), findsOneWidget);
    expect(find.text('Rotation'), findsOneWidget);
  });

  testWidgets('a paused shift shows 0.00 h and is excluded from the total',
      (tester) async {
    await pump(tester, seed: [
      adhoc(id: 'worked', date: completed), // 8.00h active
      adhoc(id: 'sick', date: DateTime(2020, 2, 1))
          .copyWith(isPaused: true, pauseReason: 'Sick'), // 0.00h paused
    ]);

    // Both shown (record visible) → 2 shifts; total is 8.00 (paused excluded).
    expect(find.text('2 shifts worked'), findsOneWidget);
    // Summary 8.00 h + the active tile's 8.00 h = 2; the paused tile shows 0.00.
    expect(find.text('8.00 h'), findsNWidgets(2));
    expect(find.text('0.00 h'), findsOneWidget);
    expect(find.textContaining('Paused'), findsOneWidget);
  });

  testWidgets('shows the empty state and disables export with no history',
      (tester) async {
    await pump(tester, seed: [
      adhoc(id: 'future-adhoc', date: future),
      adhoc(id: 'future-rota', date: future, isAdHoc: false),
      adhoc(id: 'off', date: DateTime(2020, 2, 1), type: ShiftType.off, start: 0, end: 0),
    ]);

    expect(find.text('No completed shifts yet'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('work-history-export')),
    );
    expect(button.onPressed, isNull, reason: 'nothing to export');
  });

  testWidgets('Export History hands a CSV + filename to the exporter',
      (tester) async {
    String? capturedCsv;
    String? capturedName;
    await pump(
      tester,
      seed: [adhoc(id: 'done', date: completed)],
      exporter: (csv, name) async {
        capturedCsv = csv;
        capturedName = name;
      },
    );

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('work-history-export')),
    );
    expect(button.onPressed, isNotNull, reason: 'history present → enabled');

    await tester.tap(find.byKey(const ValueKey('work-history-export')));
    await tester.pumpAndSettle();

    expect(capturedName, kWorkHistoryCsvFilename);
    expect(capturedCsv, contains(kWorkHistoryCsvHeader));
    expect(capturedCsv, contains('2020-01-01,07:00,15:00,8.00,Ad-Hoc'));
  });
}
