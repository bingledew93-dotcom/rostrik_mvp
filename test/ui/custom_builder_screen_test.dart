import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/custom_builder_screen.dart';

void main() {
  // The builder renders without providers (the ShiftGenerator is only read on
  // Generate, never on build) so a bare pump exercises the Add Block UX.
  testWidgets('Add Block auto-increments the day from the previous block',
      (tester) async {
    // Tall surface so the (scroll-view) "Add Block" button is on-screen and
    // hittable; otherwise tester.tap derives an off-screen offset and misses.
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CustomBuilderScreen()));
    await tester.pumpAndSettle();

    // Block 1 defaults to Day 1 — its Start day + End day steppers both show 1.
    final block0 = find.byKey(const ValueKey('custom-block-0'));
    expect(find.descendant(of: block0, matching: find.text('1')), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('custom-add-block')));
    await tester.pumpAndSettle();

    // Block 2 auto-advances to Day 2 (Block 1 was Day 1) — both steppers show 2.
    final block1 = find.byKey(const ValueKey('custom-block-1'));
    expect(find.descendant(of: block1, matching: find.text('2')), findsNWidgets(2));

    // The sequence continues — Block 3 defaults to Day 3.
    await tester.tap(find.byKey(const ValueKey('custom-add-block')));
    await tester.pumpAndSettle();
    final block2 = find.byKey(const ValueKey('custom-block-2'));
    expect(find.descendant(of: block2, matching: find.text('3')), findsNWidgets(2));
  });
}
