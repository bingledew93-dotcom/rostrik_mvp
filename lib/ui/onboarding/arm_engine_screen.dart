import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift_cycle.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/app_alarm_repository.dart';
import '../../data/repositories/shift_cycle_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../../logic/default_alarm_seeder.dart';
import '../shift_format.dart';
import 'onboarding_progress.dart';

/// Final onboarding step — "Arm the engine".
///
/// The roster has already been generated into Hive by the pattern picker (or
/// custom builder) before this screen is reached. This screen is the
/// confirmation hero: it reads back the generated roster, tells the user
/// exactly which alarms it's about to switch on, and arms them on a single
/// massive orange "Automate My Alarms" action.
///
/// Arming = seed one enabled follows-rotation alarm per working shift type in
/// the roster (via [seedDefaultAlarms]), then hand off to [onArmComplete] —
/// which the onboarding flow wires to flip the `onboarding_complete` flag and
/// replace the stack with the Dashboard. The completion is injected rather than
/// navigated-from-here so the arming policy stays widget-test-friendly (no
/// forced MainLayout build, no Hive write inside the screen).
class ArmEngineScreen extends StatefulWidget {
  const ArmEngineScreen({
    super.key,
    required this.onArmComplete,
    this.onBack,
  });

  /// Invoked once after alarms are seeded. The flow flips the completion flag
  /// and routes to the Dashboard here.
  final Future<void> Function() onArmComplete;

  /// Optional back affordance (returns to the pattern picker).
  final VoidCallback? onBack;

  @override
  State<ArmEngineScreen> createState() => _ArmEngineScreenState();
}

class _ArmEngineScreenState extends State<ArmEngineScreen> {
  bool _loading = true;
  bool _arming = false;
  List<ShiftType> _workTypes = const [];
  String? _cycleLabel;
  DateTime? _anchor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads back the just-generated roster to drive the summary + the set of
  /// alarms to arm. Derives work types from the materialised SHIFTS (robust for
  /// both the preset and custom-builder paths) over a 60-day window — long
  /// enough to span any rotation cycle's distinct types.
  Future<void> _load() async {
    final shiftRepo = context.read<ShiftRepository>();
    final cycleRepo = context.read<ShiftCycleRepository>();
    final now = DateTime.now();
    final shifts = await shiftRepo.getInRange(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 60),
    );
    final present = <ShiftType>{
      for (final s in shifts)
        if (s.type != ShiftType.off) s.type,
    };
    final cycle = _latestCycle(await cycleRepo.getAll());

    if (!mounted) return;
    setState(() {
      // Fixed display order Day → Afternoon → Night.
      _workTypes = const [ShiftType.day, ShiftType.afternoon, ShiftType.night]
          .where(present.contains)
          .toList();
      _cycleLabel = cycle?.label;
      _anchor = cycle?.anchorDate;
      _loading = false;
    });
  }

  static ShiftCycle? _latestCycle(List<ShiftCycle> cycles) {
    ShiftCycle? best;
    for (final c in cycles) {
      if (best == null || c.createdAt.isAfter(best.createdAt)) best = c;
    }
    return best;
  }

  Future<void> _arm() async {
    if (_arming) return;
    setState(() => _arming = true);
    final alarms = context.read<AppAlarmRepository>();
    await seedDefaultAlarms(alarms: alarms, workTypes: _workTypes);
    if (!mounted) return;
    await widget.onArmComplete();
  }

  /// "Day & Night" / "Day" — the work types we're arming, in plain English.
  String get _armingSummary {
    if (_workTypes.isEmpty) return '';
    final labels = _workTypes.map(defaultAlarmLabelFor).toList();
    if (labels.length == 1) return labels.single;
    return '${labels.sublist(0, labels.length - 1).join(', ')} & ${labels.last}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _arming ? null : widget.onBack,
              ),
        title: const Text('Arm your alarms'),
        bottom: const OnboardingProgressBar(step: 3),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    // Hero glyph — the "engine armed" mark in high-vis orange.
                    Icon(
                      Icons.bolt,
                      size: 88,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your roster is ready',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_cycleLabel != null)
                      Text(
                        _anchor == null
                            ? _cycleLabel!
                            : '$_cycleLabel · starts ${formatShiftDate(_anchor!)}',
                        key: const ValueKey('arm-engine-summary'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_workTypes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_on, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'We\'ll switch on $_armingSummary wake-up '
                                'alarms before every matching shift.',
                                key: const ValueKey('arm-engine-arming-summary'),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(flex: 3),
                    // The massive, high-vis primary action.
                    SizedBox(
                      height: 64,
                      child: FilledButton.icon(
                        key: const ValueKey('arm-engine-button'),
                        onPressed: _arming ? null : _arm,
                        icon: _arming
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.alarm_add, size: 26),
                        label: Text(
                          _arming ? 'Arming…' : 'Automate My Alarms',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ),
    );
  }
}
