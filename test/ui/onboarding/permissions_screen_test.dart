import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/onboarding/permissions_screen.dart';

void main() {
  const permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  // permission_handler Permission.value ints (platform-interface 4.x).
  const ignoreBatteryOptimizations = 16;
  // PermissionStatus indices: denied = 0, granted = 1.
  const denied = 0;
  const granted = 1;

  /// Installs a mock permission backend. [grantedValues] holds the
  /// `Permission.value` ints reported as granted; everything else is denied.
  void mockPermissions(WidgetTester tester, {Set<int> grantedValues = const {}}) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permChannel,
      (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            final value = call.arguments as int;
            return grantedValues.contains(value) ? granted : denied;
          case 'requestPermissions':
            return <int, int>{};
          case 'openAppSettings':
            return true;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(permChannel, null));
  }

  Future<void> pumpPermissions(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionsScreen(onBack: () {}, onContinue: () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('battery card is an education tile — no toggle switch',
      (tester) async {
    mockPermissions(tester); // all denied
    await pumpPermissions(tester);

    expect(find.text('Battery Unrestricted'), findsOneWidget);
    // Only Notifications + Exact Alarms carry switches; the battery card
    // does NOT — it routes through the educational dialog instead.
    expect(find.byType(Switch), findsNWidgets(2));
    // Ungranted → a chevron invites the tap.
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      find.byKey(const ValueKey('battery-unrestricted-badge')),
      findsNothing,
    );
  });

  testWidgets('tapping the battery card opens the Battery Survival dialog',
      (tester) async {
    mockPermissions(tester);
    await pumpPermissions(tester);

    await tester.tap(find.text('Battery Unrestricted'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('battery-survival-dialog')),
      findsOneWidget,
    );
    expect(find.text('Keep alarms alive'), findsOneWidget);
  });

  testWidgets('granted battery status shows the Unrestricted badge',
      (tester) async {
    mockPermissions(tester, grantedValues: {ignoreBatteryOptimizations});
    await pumpPermissions(tester);

    expect(
      find.byKey(const ValueKey('battery-unrestricted-badge')),
      findsOneWidget,
    );
    expect(find.text('Unrestricted'), findsOneWidget);
    // The chevron is replaced by the badge once granted.
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
