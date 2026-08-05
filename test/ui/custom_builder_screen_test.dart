import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';
import 'package:rostrik_mvp/ui/custom_builder_screen.dart';

import '../alarms/fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late ShiftGenerator generator;

  setUp(() {
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    generator = ShiftGenerator(shifts: shifts, cycles: cycles);
  });

  tearDown(() async {
    await shifts.dispose();
    await cycles.dispose();
  });

  Future<void> pumpBuilder(WidgetTester tester) async {
    // Tall surface so the scroll-view content (Create button, blocks) is
    // reachable without scrolling in most assertions.
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Provider<ShiftGenerator>.value(
        value: generator,
        child: const MaterialApp(home: CustomBuilderScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Adds one painted block covering days 1..[dayCount] of the given [type]
  /// via the Add Shift Block sheet.
  Future<void> addBlock(
    WidgetTester tester, {
    int dayCount = 3,
  }) async {
    await tester.tap(find.byKey(const ValueKey('roster-add-block')));
    await tester.pumpAndSettle();
    for (var i = 0; i < dayCount; i++) {
      await tester.tap(find.byKey(ValueKey('block-day-$i')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('block-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the New Shift Roster header, chips and empty blocks',
      (tester) async {
    await pumpBuilder(tester);
    expect(find.text('New Shift Roster'), findsOneWidget);
    expect(find.byKey(const ValueKey('cycle-chip-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('cycle-chip-42')), findsOneWidget);
    expect(find.byKey(const ValueKey('cycle-chip-custom')), findsOneWidget);
    expect(find.byKey(const ValueKey('roster-blocks-empty')), findsOneWidget);
    // Create is disabled until a working day is painted.
    final create = tester.widget<FilledButton>(
      find.byKey(const ValueKey('roster-create')),
    );
    expect(create.onPressed, isNull);
  });

  testWidgets('the Custom chip reveals the cycle-length stepper',
      (tester) async {
    await pumpBuilder(tester);
    expect(find.byKey(const ValueKey('cycle-custom-value')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cycle-chip-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cycle-custom-value')), findsOneWidget);
    // Stepping changes the value.
    await tester.tap(find.byKey(const ValueKey('cycle-custom-plus')));
    await tester.pumpAndSettle();
    expect(find.text('15 days'), findsOneWidget);
  });

  testWidgets('painting a block adds it to the list and enables Create',
      (tester) async {
    await pumpBuilder(tester);
    await addBlock(tester, dayCount: 3);

    // Block tile shows the type + the painted day range.
    expect(find.byKey(const ValueKey('roster-block-0')), findsOneWidget);
    expect(find.textContaining('Days 1–3'), findsOneWidget);

    final create = tester.widget<FilledButton>(
      find.byKey(const ValueKey('roster-create')),
    );
    expect(create.onPressed, isNotNull);
  });

  testWidgets('a day covered by another block is still selectable (split)',
      (tester) async {
    await pumpBuilder(tester);
    await addBlock(tester, dayCount: 3); // covers days 0,1,2

    // Open a second block sheet — day 0 stays tappable so it can take a split.
    await tester.tap(find.byKey(const ValueKey('roster-add-block')));
    await tester.pumpAndSettle();
    final sharedCell = tester.widget<InkWell>(
      find.byKey(const ValueKey('block-day-0')),
    );
    expect(sharedCell.onTap, isNotNull, reason: 'claimed day allows a split');
  });

  testWidgets('a second block on free days is added', (tester) async {
    await pumpBuilder(tester);
    await addBlock(tester, dayCount: 2); // block 0 covers days 0,1

    // Second block on days 3,4 (free) — no clash, so it's added.
    await tester.tap(find.byKey(const ValueKey('roster-add-block')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('block-day-3')));
    await tester.tap(find.byKey(const ValueKey('block-day-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('block-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('roster-block-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('roster-block-1')), findsOneWidget);
  });

  testWidgets('a clashing split is flagged live and blocks Save', (tester) async {
    await pumpBuilder(tester);
    await addBlock(tester, dayCount: 3); // block 0: Day 07:00–15:00 on days 0,1,2

    // Second block keeps the default 07:00–15:00 times; painting day 0 (shared)
    // clashes → the conflict message shows and Save is disabled, immediately.
    await tester.tap(find.byKey(const ValueKey('roster-add-block')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('block-day-0')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('block-conflict-message')),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('block-save')),
    );
    expect(save.onPressed, isNull, reason: 'a time clash blocks Save live');

    // Move to a free day (5) — conflict clears and Save enables.
    await tester.tap(find.byKey(const ValueKey('block-day-0'))); // deselect
    await tester.tap(find.byKey(const ValueKey('block-day-5'))); // free
    await tester.pump();
    expect(
      find.byKey(const ValueKey('block-conflict-message')),
      findsNothing,
    );
    final save2 = tester.widget<FilledButton>(
      find.byKey(const ValueKey('block-save')),
    );
    expect(save2.onPressed, isNotNull);
  });

  testWidgets('Create Roster persists an anchored cycle + materialised shifts',
      (tester) async {
    await pumpBuilder(tester); // default 14-day cycle
    await addBlock(tester, dayCount: 4); // Day shift on days 1–4

    await tester.tap(find.byKey(const ValueKey('roster-create')));
    await tester.pumpAndSettle();

    // An anchored cycle was created…
    final saved = await cycles.getAll();
    expect(saved, hasLength(1));
    expect(saved.single.isAnchored, isTrue);
    expect(saved.single.anchorDate, isNotNull);

    // …and a 365-day window of shifts was materialised, with 4 working Day
    // shifts per 14-day cycle and the rest Off.
    final allShifts = await shifts.getAll();
    expect(allShifts, isNotEmpty);
    final dayShifts = allShifts.where((s) => s.type == ShiftType.day).length;
    // ~365/14 ≈ 26 cycles × 4 = ~104 Day shifts. Loose bound: definitely > 50.
    expect(dayShifts, greaterThan(50));
    expect(allShifts.any((s) => s.type == ShiftType.off), isTrue);
  });

  testWidgets('Create is blocked when no day is painted (all-Off guard)',
      (tester) async {
    await pumpBuilder(tester);
    // Add a block but paint NO days → the sheet's own Save is disabled, so no
    // block is added and Create stays disabled.
    await tester.tap(find.byKey(const ValueKey('roster-add-block')));
    await tester.pumpAndSettle();
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('block-save')),
    );
    expect(save.onPressed, isNull);
  });
}
