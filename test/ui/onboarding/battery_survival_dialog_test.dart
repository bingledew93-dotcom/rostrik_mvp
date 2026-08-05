import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/onboarding/battery_survival_dialog.dart';

void main() {
  // permission_handler routes openAppSettings() through this channel.
  const permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  /// Pumps a host with a button that opens the dialog, then taps it.
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showBatterySurvivalDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the OEM-killer explanation, numbered steps and actions',
      (tester) async {
    await openDialog(tester);

    expect(find.byKey(const ValueKey('battery-survival-dialog')), findsOneWidget);
    expect(find.text('Keep alarms alive'), findsOneWidget);
    // The "why" — vendor app-killers.
    expect(find.textContaining('background apps'), findsOneWidget);
    // The numbered recovery steps (the chip numbers) — now five, incl. the
    // Android-hibernation auto-revoke warning.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('Unrestricted'), findsWidgets);
    // The hibernation step names the OEM toggle variants the user must disable.
    expect(find.textContaining('Pause app activity'), findsOneWidget);
    expect(find.textContaining('Remove permissions'), findsOneWidget);
    // Both actions present.
    expect(find.byKey(const ValueKey('battery-go-to-settings')), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('"Not now" dismisses without opening settings', (tester) async {
    var openSettingsCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permChannel,
      (call) async {
        if (call.method == 'openAppSettings') openSettingsCalls++;
        return true;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(permChannel, null));

    await openDialog(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battery-survival-dialog')), findsNothing);
    expect(openSettingsCalls, 0);
  });

  testWidgets('"Go to Settings" fires openAppSettings then closes the dialog',
      (tester) async {
    var openSettingsCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permChannel,
      (call) async {
        if (call.method == 'openAppSettings') openSettingsCalls++;
        return true; // wasOpened
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(permChannel, null));

    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('battery-go-to-settings')));
    await tester.pumpAndSettle();

    expect(openSettingsCalls, 1);
    expect(find.byKey(const ValueKey('battery-survival-dialog')), findsNothing);
  });
}
