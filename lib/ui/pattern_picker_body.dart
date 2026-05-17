import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift_type.dart';
import '../logic/rotation_pattern.dart';
import '../logic/rotation_pattern_validator.dart';
import '../logic/shift_generator.dart';
import 'custom_builder_screen.dart';
import 'onboarding/onboarding_state.dart';
import 'roster/shift_visuals.dart';
import 'shift_format.dart';

/// Shared body widget for the Pattern Picker. Powers both the
/// post-onboarding picker ([PatternPickerScreen]) and the onboarding
/// step-4 picker ([PatternPickerOnboardingScreen]) — they wrap this
/// in their own Scaffold chrome and supply different [onGenerated]
/// callbacks.
///
/// Renders (top to bottom):
///   1. Filtered category sections — "Rotating Swings", "Day Only
///      Swings", "Night Only Swings". When [restrictToType] is null
///      all three render; when set, only the matching one does.
///   2. Per-shift-type time editor for the currently selected preset
///      (one row per distinct non-OFF block type). OFF blocks are
///      omitted — no times to override.
///   3. "Set Day 1 & Generate" button. Disabled until a preset is
///      selected; on tap opens a Material date picker with "Next
///      Day 1" copy, then calls `generateAndPersistPattern` with the
///      synthesised pattern + a 365-day materialisation horizon.
///   4. "Build custom roster" escape hatch. Pushes the
///      [CustomBuilderScreen]; if the user generates a roster there
///      (CustomBuilderScreen pops `true`), this body also fires
///      [onGenerated] — uniform success path regardless of which
///      route the user took.
class PatternPickerBody extends StatefulWidget {
  const PatternPickerBody({
    super.key,
    this.restrictToType,
    required this.onGenerated,
  });

  /// When non-null, only the category section matching this roster
  /// type renders. Onboarding uses this (the user picked a roster
  /// type on step 3); post-onboarding leaves it null.
  final RosterType? restrictToType;

  /// Fired exactly once after a successful roster generation, whether
  /// the user took the preset path OR the Custom Builder path. The
  /// caller owns the after-success behaviour: pop the screen, set the
  /// `onboarding_complete` Hive flag, push MainLayout, etc.
  final VoidCallback onGenerated;

  @override
  State<PatternPickerBody> createState() => _PatternPickerBodyState();
}

/// Editable time window for one shift type within the picker. Mirrors
/// the `(startMinutes, endMinutes)` shape `RotationBlock` carries, but
/// per *type* rather than per *block* — all blocks of the same type
/// inside a preset adopt the same edited window when the user
/// customises.
@immutable
class _ShiftTimes {
  const _ShiftTimes(this.startMinutes, this.endMinutes);
  final int startMinutes;
  final int endMinutes;
}

class _PatternPickerBodyState extends State<PatternPickerBody> {
  /// Upfront materialisation horizon (days) handed to the generator.
  /// Matches `onboarding_flow.dart`'s historical horizon and the
  /// AlarmSyncService scheduling horizon — see the
  /// `phase5-no-background-isolates` project memory.
  static const int _materialiseDays = 365;

  RotationPattern? _selected;
  final Map<ShiftType, _ShiftTimes> _editedTimes = {};
  bool _generating = false;

  bool get _canGenerate => _selected != null && !_generating;

  void _selectPreset(RotationPattern p) {
    // Re-selecting the same preset is a no-op — without this, a user
    // who tapped their selected tile again would silently lose their
    // edited times to a re-seed.
    if (_selected?.id == p.id) return;
    setState(() {
      _selected = p;
      _editedTimes.clear();
      for (final block in p.blocks) {
        if (block.type == ShiftType.off) continue;
        // First occurrence of each type seeds the edit window. If a
        // pattern ever ships with two blocks of the same type at
        // different times, they'd share the first one's window.
        _editedTimes.putIfAbsent(
          block.type,
          () => _ShiftTimes(block.startMinutes, block.endMinutes),
        );
      }
    });
  }

  Future<void> _pickShiftStart(ShiftType type) async {
    final current = _editedTimes[type]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.startMinutes ~/ 60,
        minute: current.startMinutes % 60,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _editedTimes[type] = _ShiftTimes(
        picked.hour * 60 + picked.minute,
        current.endMinutes,
      );
    });
  }

  Future<void> _pickShiftEnd(ShiftType type) async {
    final current = _editedTimes[type]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.endMinutes ~/ 60,
        minute: current.endMinutes % 60,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _editedTimes[type] = _ShiftTimes(
        current.startMinutes,
        picked.hour * 60 + picked.minute,
      );
    });
  }

  Future<void> _onGeneratePressed() async {
    if (!_canGenerate) return;
    final pattern = _selected!;
    final firstBlockLabel = _firstBlockHumanLabel(pattern);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      helpText: 'Select your Next Day 1',
      fieldHintText: 'First day of your $firstBlockLabel block',
      fieldLabelText: 'Next Day 1',
      confirmText: 'Use this date',
    );
    if (picked == null || !mounted) return;
    await _generate(pattern, picked);
  }

  Future<void> _generate(RotationPattern p, DateTime anchor) async {
    setState(() => _generating = true);

    // Capture context-dependent refs BEFORE the await so we can't read
    // `context` across the async gap.
    final generator = context.read<ShiftGenerator>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Synthesise a pattern with the user's edited times applied. OFF
      // blocks pass through unchanged (they have no times to override);
      // typed blocks adopt the user's edits across all occurrences.
      final blocks = p.blocks.map((b) {
        if (b.type == ShiftType.off) return b;
        final edited = _editedTimes[b.type];
        if (edited == null) return b;
        return RotationBlock(
          type: b.type,
          consecutiveDays: b.consecutiveDays,
          startMinutes: edited.startMinutes,
          endMinutes: edited.endMinutes,
        );
      }).toList();
      final customPattern = RotationPattern(
        id: p.id,
        label: p.label,
        summary: p.summary,
        blocks: blocks,
      );

      // generateAndPersistPattern auto-anchors the resulting cycle
      // (anchorDate + blocks) per the "every cycle must be anchored"
      // invariant. endDate is anchor + 365 days to match the upfront
      // materialisation horizon.
      final shifts = await generator.generateAndPersistPattern(
        pattern: customPattern,
        startDate: anchor,
        endDate: DateTime(anchor.year, anchor.month, anchor.day + _materialiseDays),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Generated ${shifts.length} shifts')),
      );
      widget.onGenerated();
    } on RosterGenerationException catch (e) {
      // Validator / time-overlap rejection — surface verbatim. Nothing
      // was written; picker stays open.
      if (!mounted) return;
      setState(() => _generating = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  Future<void> _onCustomBuilderTapped() async {
    // CustomBuilderScreen pops `true` on a successful generate, `null`
    // on Cancel / back. Fire onGenerated only on the success signal so
    // a user who opened the builder, browsed, and backed out doesn't
    // accidentally trigger the post-success path.
    final generated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CustomBuilderScreen()),
    );
    if (generated == true && mounted) {
      widget.onGenerated();
    }
  }

  /// "Day" / "Night" / "Off" derived from the first block of a preset.
  /// Feeds the date-picker hint text so the user knows which block
  /// their anchor will land on.
  static String _firstBlockHumanLabel(RotationPattern p) {
    if (p.blocks.isEmpty) return 'first';
    switch (p.blocks.first.type) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        return 'Off';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restrict = widget.restrictToType;
    final showRotating = restrict == null || restrict == RosterType.rotating;
    final showDay = restrict == null || restrict == RosterType.day;
    final showNight = restrict == null || restrict == RosterType.night;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showRotating) ...[
              _CategorySection(
                title: 'Rotating Swings',
                presets: kRotatingPatterns,
                selectedId: _selected?.id,
                onPresetTapped: _selectPreset,
              ),
              const SizedBox(height: 16),
            ],
            if (showDay) ...[
              _CategorySection(
                title: 'Day Only Swings',
                presets: kDayPatterns,
                selectedId: _selected?.id,
                onPresetTapped: _selectPreset,
              ),
              const SizedBox(height: 16),
            ],
            if (showNight) ...[
              _CategorySection(
                title: 'Night Only Swings',
                presets: kNightPatterns,
                selectedId: _selected?.id,
                onPresetTapped: _selectPreset,
              ),
            ],

            // Per-type time editor — appears the moment a preset with
            // any non-OFF block is selected. Edits apply at Generate
            // time via the synthesised RotationPattern.
            if (_selected != null && _editedTimes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Shift times',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in _editedTimes.entries)
                _ShiftTimesRow(
                  key: ValueKey('shift-times-${entry.key.name}'),
                  type: entry.key,
                  times: entry.value,
                  onPickStart: () => _pickShiftStart(entry.key),
                  onPickEnd: () => _pickShiftEnd(entry.key),
                ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('pattern-picker-generate'),
              onPressed: _canGenerate ? _onGeneratePressed : null,
              child: _generating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set Day 1 & Generate'),
            ),

            const SizedBox(height: 24),
            _CustomBuilderEntryTile(
              onTap: _generating ? null : _onCustomBuilderTapped,
            ),
          ],
        ),
      ),
    );
  }
}

/// One category section: header + a column of preset tiles.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.presets,
    required this.selectedId,
    required this.onPresetTapped,
  });

  final String title;
  final List<RotationPattern> presets;
  final String? selectedId;
  final ValueChanged<RotationPattern> onPresetTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final p in presets)
          _PresetTile(
            key: ValueKey('pattern-tile-${p.id}'),
            pattern: p,
            selected: selectedId == p.id,
            onTap: () => onPresetTapped(p),
          ),
      ],
    );
  }
}

/// One preset tile.
///
/// Built from raw primitives (no `ListTile`) so the cycle strip's
/// width constraint chain is fully under our control:
///
///   Card → InkWell → Padding → Row → Expanded → Column(stretch)
///         → SizedBox(height: 8) → CycleStrip
///
/// `ListTile.subtitle`'s slot has internal height/width
/// negotiations that intermittently collapse a multi-element Column
/// subtitle (visible on real devices, invisible in widget tests).
/// Building the tile by hand removes that variable entirely — the
/// strip's parent is always an `Expanded` inside a `Row` with a known
/// bounded width.
class _PresetTile extends StatelessWidget {
  const _PresetTile({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
  });

  final RotationPattern pattern;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      // clipBehavior so the InkWell ripple respects the Card's
      // rounded corners instead of bleeding to a square edge.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              // Expanded → Column(stretch) is the guarantee that
              // CycleStrip below receives a TIGHT, BOUNDED width
              // constraint. Without Expanded, the Row would shrink-
              // wrap; without Column.stretch, the strip would get a
              // loose constraint and the all-Expanded Row inside
              // CycleStrip would collapse to 0 width.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pattern.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Outer SizedBox enforces the strip's height
                    // from above; CycleStrip's internal
                    // LayoutBuilder enforces width from inside.
                    // Belt-and-braces — if either ancestor ever
                    // mis-passes a constraint, the other layer
                    // still gives the strip a finite render box.
                    SizedBox(
                      height: 8,
                      child: CycleStrip(blocks: pattern.blocks),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Proportional colour strip for one full cycle. Each block becomes
/// an [Expanded] segment whose flex equals its `consecutiveDays`, so
/// segment widths are automatically proportional to the total cycle
/// length — no manual percentage math.
///
/// Colour palette comes from [visualFor] so the strip stays in sync
/// with Calendar cells and Dashboard cards (Day = Amber, Night =
/// Indigo, Off = Grey, Afternoon = Orange).
class CycleStrip extends StatelessWidget {
  const CycleStrip({super.key, required this.blocks});

  final List<RotationBlock> blocks;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder reads the EXACT constraints handed down by the
    // immediate parent. We then pin SizedBox to the concrete pixel
    // width, which guarantees the inner Row gets a tight, bounded
    // width and the all-Expanded children can distribute proportional
    // flex without collapsing.
    //
    // Fallback to 240px if our ancestor ever hands us an unbounded
    // width — should never trigger inside _PresetTile (the Expanded
    // → Column(stretch) chain always provides bounded width), but
    // safer than throwing in production if the widget is reused
    // somewhere with looser parent constraints later.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 240.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: width,
            height: 8,
            child: Row(
              children: [
                for (final b in blocks)
                  Expanded(
                    flex: b.consecutiveDays,
                    child: ColoredBox(color: visualFor(b.type).color),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One editable row in the "Shift times" section. Two outlined-button
/// time pickers (start, end) flanking an arrow. The label maps the
/// shift type to a human-readable noun.
class _ShiftTimesRow extends StatelessWidget {
  const _ShiftTimesRow({
    super.key,
    required this.type,
    required this.times,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final ShiftType type;
  final _ShiftTimes times;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  String get _label => switch (type) {
        ShiftType.day => 'Day shift',
        ShiftType.afternoon => 'Afternoon shift',
        ShiftType.night => 'Night shift',
        // Unreachable: parent guards on `type != off` before rendering.
        ShiftType.off => 'Off',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(_label, style: theme.textTheme.bodyLarge),
          ),
          OutlinedButton(
            key: ValueKey('shift-times-${type.name}-start'),
            onPressed: onPickStart,
            child: Text(formatHhmm(times.startMinutes)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton(
            key: ValueKey('shift-times-${type.name}-end'),
            onPressed: onPickEnd,
            child: Text(formatHhmm(times.endMinutes)),
          ),
        ],
      ),
    );
  }
}

/// Distinct entry tile that pushes the custom builder. Outlined (not
/// Card) so it doesn't read as another preset; the trailing chevron
/// signals "this opens another screen".
class _CustomBuilderEntryTile extends StatelessWidget {
  const _CustomBuilderEntryTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      key: const ValueKey('pattern-picker-build-custom'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Build custom roster',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Doesn't fit a preset? Compose your own blocks.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
