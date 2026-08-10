import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../logic/cycle_service.dart';
import '../logic/cycle_to_painted.dart';
import '../logic/painted_roster.dart';
import '../logic/rotation_pattern_validator.dart' show RosterGenerationException;
import '../logic/shift_generator.dart';
import '../ocr/ocr_scanner_service.dart';
import '../ocr/roster_injection.dart';
import '../roster_ai/roster_ai_parser.dart';
import '../state/app_preferences.dart';
import 'draft_roster_review_screen.dart';
import 'import_ai_modal.dart';
import 'roster/shift_visuals.dart';
import 'shift_format.dart';
import 'time_picker_pref.dart';

/// "New Shift Roster" — the redesigned custom-roster builder.
///
/// The old builder made a 6-week roster a slog: a numeric cycle-length field, a
/// numeric repeat count, and one positional block at a time. This version cuts
/// the friction the way the field feedback asked for:
///   * **Cycle length is a chip row** (7/8/14/21/28/42 + Custom) — one tap.
///   * **Shift blocks are painted** onto a day grid inside an "Add Shift Block"
///     sheet: set the type + times once, then tap every day it covers. Any
///     un-painted day is automatically Off.
///   * **The roster repeats forever.** There is no repeat count — Create Roster
///     persists an ANCHORED cycle ([ShiftGenerator.generateAndPersistAnchored])
///     that the modulo resolver projects indefinitely, materialising a 365-day
///     window for the alarm engine.
///
/// Reachable (unchanged route contract — pushed, pops `true` on a successful
/// create) from the pattern-picker's "Build custom roster" escape hatch and the
/// onboarding Custom card. The OCR scan path (Phase 6) is preserved as a
/// secondary action.
class CustomBuilderScreen extends StatefulWidget {
  const CustomBuilderScreen({super.key, this.scanner, this.editCycle});

  /// Injectable for tests. Null in production, where the screen lazily owns a
  /// real [OcrScannerService] and disposes it. The real one is never
  /// constructed unless the user actually triggers a scan, so widget tests
  /// that only render the builder never touch ML Kit / the camera.
  final OcrScannerService? scanner;

  /// When non-null the screen opens in EDIT mode, pre-filled from this saved
  /// roster (name, cycle length, painted blocks, anchored start). Saving
  /// REPLACES it: the new roster is generated, then this cycle is
  /// cascade-deleted. Only reconstructable (anchored, ≤60-day) cycles are ever
  /// passed here — see [isCycleEditable].
  final ShiftCycle? editCycle;

  @override
  State<CustomBuilderScreen> createState() => _CustomBuilderScreenState();
}

class _CustomBuilderScreenState extends State<CustomBuilderScreen> {
  static const _uuid = Uuid();
  static const int _minCycleDays = 1;
  static const int _maxCycleDays = 60;

  /// The preset chip values, matching the design. "Custom" is a 7th option that
  /// reveals a stepper for any length in `[_minCycleDays, _maxCycleDays]`.
  static const List<int> _presetLengths = <int>[7, 8, 14, 21, 28, 42];

  final TextEditingController _nameController = TextEditingController();
  int _cycleLengthDays = 14;
  bool _customLength = false;
  DateTime? _startDate;
  final List<PaintedShiftBlock> _blocks = <PaintedShiftBlock>[];
  bool _generating = false;
  bool _scanning = false;
  String? _validationError;

  // Lazily created only on first scan so rendering the builder (incl. in
  // tests) never spins up ML Kit. Disposed in [dispose] iff we own it;
  // an injected `widget.scanner` belongs to the caller.
  OcrScannerService? _ownedScanner;
  OcrScannerService get _scanner =>
      widget.scanner ?? (_ownedScanner ??= OcrScannerService());

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);

    // EDIT mode: pre-fill the builder from the saved roster.
    final editing = widget.editCycle;
    if (editing != null) {
      final reconstructed = reconstructRosterFromCycle(editing);
      if (reconstructed != null) {
        _nameController.text = editing.label;
        _cycleLengthDays = reconstructed.cycleLengthDays;
        _customLength = !_presetLengths.contains(_cycleLengthDays);
        _blocks.addAll(reconstructed.blocks);
        // Preserve the rotation's phase: keep its original anchor (even if in
        // the past) so changing a shift time doesn't shift which cycle-day
        // "today" lands on. The user can still re-pick the start date.
        _startDate = editing.anchorDate ?? _startDate;
      }
    }
  }

  bool get _isEditing => widget.editCycle != null;

  static DateTime _laterOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  @override
  void dispose() {
    _nameController.dispose();
    _ownedScanner?.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      !_generating &&
      !_scanning &&
      _startDate != null &&
      hasAnyPaintedDay(_blocks);

  void _selectPresetLength(int v) {
    setState(() {
      _customLength = false;
      _cycleLengthDays = v;
      _pruneDaysBeyondCycle();
      _validationError = null;
    });
  }

  void _selectCustomLength() {
    setState(() {
      _customLength = true;
      _validationError = null;
    });
  }

  void _setCustomLength(int v) {
    setState(() {
      _cycleLengthDays = v.clamp(_minCycleDays, _maxCycleDays);
      _pruneDaysBeyondCycle();
      _validationError = null;
    });
  }

  /// Drops any painted day position that now sits past the cycle end (after the
  /// length shrinks), and removes a block left with no days.
  void _pruneDaysBeyondCycle() {
    for (var i = _blocks.length - 1; i >= 0; i--) {
      final kept = _blocks[i].dayIndices.where((d) => d < _cycleLengthDays);
      if (kept.isEmpty) {
        _blocks.removeAt(i);
      } else if (kept.length != _blocks[i].dayIndices.length) {
        _blocks[i] = _blocks[i].copyWith(dayIndices: kept.toSet());
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
      helpText: 'Pick the roster start date',
    );
    if (!mounted || picked == null) return;
    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  /// Opens the paintbrush sheet to add a new block, or edit [existingIndex].
  Future<void> _openBlockSheet({int? existingIndex}) async {
    final editing = existingIndex != null ? _blocks[existingIndex] : null;
    final result = await showModalBottomSheet<PaintedShiftBlock>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddShiftBlockSheet(
        cycleLength: _cycleLengthDays,
        // The OTHER blocks — the sheet marks their days (a tap there makes a
        // split) and flags, live as the user paints, any day where THIS block's
        // time would clash with one of them (an illegal split), so overlaps are
        // fixed on the spot instead of at Create.
        otherBlocks: [
          for (var i = 0; i < _blocks.length; i++)
            if (i != existingIndex) _blocks[i],
        ],
        existing: editing,
        use24Hour: AppPreferences.use24HourOf(context),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (existingIndex != null) {
        _blocks[existingIndex] = result;
      } else {
        _blocks.add(result);
      }
      _validationError = null;
    });
  }

  void _removeBlock(int i) {
    setState(() {
      _blocks.removeAt(i);
      _validationError = null;
    });
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() {
      _generating = true;
      _validationError = null;
    });

    // Capture before the awaits — BuildContext is unsafe across suspensions.
    final generator = context.read<ShiftGenerator>();
    final editCycle = widget.editCycle;
    // Only needed for the replace step; read it now so no context is used post-await.
    final cycleService = editCycle != null ? context.read<CycleService>() : null;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final start = _startDate!;
    final name = _nameController.text.trim();

    // Always materialise at least a full year from today, and (when editing an
    // old anchor) at least one window from the anchor, so future coverage is
    // never thin regardless of how far back the anchor sits.
    final now = DateTime.now();
    final materialiseTo = _laterOf(
      DateTime(start.year, start.month, start.day + 365),
      DateTime(now.year, now.month, now.day + 365),
    );

    try {
      final shifts = await generator.generateAndPersistCustom(
        label: name.isEmpty
            ? (editCycle?.label ?? 'Custom roster')
            : name,
        startDate: start,
        cycleLengthDays: _cycleLengthDays,
        // Per-day positional blocks — two blocks on the same day materialise as
        // a SPLIT shift; the generator rejects only time-overlapping pairs.
        blocks: paintedBlocksToShiftBlocks(_blocks),
        // Forever: the cycle is anchored (projects indefinitely); we materialise
        // a 365-day window now, rolled forward by the invisible extender.
        materialiseTo: materialiseTo,
        // Un-painted days render as explicit Off/rest days on the calendar.
        fillOffDays: true,
        summary: 'Custom · $_cycleLengthDays-day cycle · repeats',
        // EDIT: exclude the roster we're replacing from the overlap check so it
        // doesn't clash with its own current shifts.
        excludeCycleIdFromOverlap: editCycle?.id,
      );
      // REPLACE: the new roster is now persisted; cascade-delete the old one
      // (its shifts + any pending alarms). Ordered new-then-old so a generate
      // failure above leaves the original roster fully intact.
      if (cycleService != null && editCycle != null) {
        await cycleService.deleteCycle(editCycle.id);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Roster updated — ${shifts.length} shifts scheduled'
                : 'Created — ${shifts.length} shifts scheduled',
          ),
        ),
      );
      navigator.pop(true);
    } on RosterGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _validationError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _validationError = 'Could not create the roster: $e';
      });
    }
  }

  // ---- Import Roster via AI Bridge (Phase 2) ----------------------------

  /// Opens the AI-bridge sheet. The parsed shifts carry absolute dates, so they
  /// persist as concrete standalone [Shift] records (`cycleId` null) via
  /// [ShiftGenerator.importDatedShifts] — never a repeating cycle. On success
  /// the sheet closes and, like a manual Create / a scan commit, this screen
  /// pops `true` so the caller fires its post-create path.
  Future<void> _openAiImport() async {
    final generator = context.read<ShiftGenerator>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final imported = await showImportAiModal(
      context,
      onImport: (List<ParsedShift> parsed) async {
        final shifts = <Shift>[
          for (final p in parsed)
            Shift(
              id: _uuid.v4(),
              date: p.date,
              type: p.type,
              startMinutes: p.startMinutes,
              endMinutes: p.endMinutes,
            ),
        ];
        try {
          await generator.importDatedShifts(shifts);
          return null; // success — the sheet closes itself.
        } on RosterGenerationException catch (e) {
          return e.message; // shown inline in the sheet; nothing was written.
        } catch (e) {
          return 'Could not import the roster: $e';
        }
      },
    );

    if (imported == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Roster imported to your calendar')),
      );
      navigator.pop(true);
    }
  }

  // ---- OCR roster scanner (Phase 6, preserved) --------------------------

  /// Camera/gallery → [DraftRosterReviewScreen] (the human-in-the-loop review).
  /// If the review commits (`true`), this screen pops `true` too so the caller
  /// fires its post-create path, exactly like a manual Create.
  Future<void> _scanEntry({required bool fromGallery}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final anchor = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
      helpText: 'Pick the start date for the scanned roster',
    );
    if (!mounted || anchor == null) return;

    setState(() => _scanning = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ScanResult result;
    try {
      result = fromGallery
          ? await _scanner.scanFromGalleryForReview()
          : await _scanner.scanRosterForReview();
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      messenger.showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _scanning = false);

    if (result.blocks.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No shift times recognised. Try cropping tighter '
            'around the grid.'),
      ));
      return;
    }

    final name = _nameController.text.trim();
    final saved = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => DraftRosterReviewScreen(
          anchorDate: DateTime(anchor.year, anchor.month, anchor.day),
          blocks: ScannedRosterInjection.map(result.blocks),
          sourceImage: result.croppedImage,
          label: name.isEmpty ? 'Scanned roster' : name,
        ),
      ),
    );
    if (saved == true && mounted) navigator.pop(true);
  }

  void _showScanOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('roster-scan-camera'),
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Scan with camera'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _scanEntry(fromGallery: false);
              },
            ),
            ListTile(
              key: const ValueKey('roster-scan-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Import a screenshot'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _scanEntry(fromGallery: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: title + subtitle + close (pop with no result).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Roster' : 'New Shift Roster',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Change and replace this saved roster'
                              : 'Set up your shift rotation pattern',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('roster-close'),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    key: const ValueKey('roster-name'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Roster name (e.g. My 14-Day Rotation)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel(theme, 'CYCLE LENGTH'),
                  const SizedBox(height: 8),
                  _buildCycleChips(theme),
                  if (_customLength) ...[
                    const SizedBox(height: 12),
                    _buildCustomLengthStepper(theme),
                  ],
                  const SizedBox(height: 24),
                  _sectionLabel(theme, 'START DATE'),
                  const SizedBox(height: 8),
                  _buildStartDateField(theme),
                  const SizedBox(height: 24),
                  _sectionLabel(theme, 'SHIFT BLOCKS'),
                  const SizedBox(height: 8),
                  _buildBlocksSection(theme),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('roster-add-block'),
                    onPressed: (_generating || _scanning)
                        ? null
                        : () => _openBlockSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Shift Block'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(theme, _validationError!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('roster-create'),
                    onPressed: _canCreate ? _create : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: _generating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Create Roster'),
                  ),
                  // EDIT mode is a REPLACE: no import/scan escape hatches (those
                  // add separate shifts), just a heads-up that per-shift marks
                  // reset. Otherwise show the "back / import an existing roster"
                  // options as before.
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Saving replaces this roster. Any leave / time-off marks '
                      'painted on it will reset.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        key: const ValueKey('roster-back-to-options'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Back to options'),
                      ),
                    ),
                    const Divider(height: 32),
                    _sectionLabel(theme, 'OR IMPORT AN EXISTING ROSTER'),
                    const SizedBox(height: 10),
                    // AI-bridge import (Phase 2): paste any roster into an AI app,
                    // paste its reply back, and land dated shifts on the calendar.
                    OutlinedButton.icon(
                      key: const ValueKey('roster-ai-import-entry'),
                      onPressed:
                          (_generating || _scanning) ? null : _openAiImport,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Import via AI'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // OCR scan preserved as a secondary path (not in the primary
                    // flow, but a shipped feature we don't want to lose).
                    Center(
                      child: TextButton.icon(
                        key: const ValueKey('roster-scan-entry'),
                        onPressed: (_generating || _scanning)
                            ? null
                            : _showScanOptions,
                        icon: const Icon(Icons.document_scanner_outlined,
                            size: 18),
                        label: Text(
                          _scanning
                              ? 'Scanning…'
                              : 'Scan a roster photo instead',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      );

  Widget _buildCycleChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final len in _presetLengths)
          ChoiceChip(
            key: ValueKey('cycle-chip-$len'),
            label: Text('${len}d'),
            selected: !_customLength && _cycleLengthDays == len,
            onSelected: (_) => _selectPresetLength(len),
          ),
        ChoiceChip(
          key: const ValueKey('cycle-chip-custom'),
          label: const Text('Custom'),
          selected: _customLength,
          onSelected: (_) => _selectCustomLength(),
        ),
      ],
    );
  }

  Widget _buildCustomLengthStepper(ThemeData theme) {
    return Row(
      children: [
        Text('Cycle length', style: theme.textTheme.bodyMedium),
        const Spacer(),
        IconButton(
          key: const ValueKey('cycle-custom-minus'),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _cycleLengthDays > _minCycleDays
              ? () => _setCustomLength(_cycleLengthDays - 1)
              : null,
        ),
        Text(
          '$_cycleLengthDays days',
          key: const ValueKey('cycle-custom-value'),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          key: const ValueKey('cycle-custom-plus'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _cycleLengthDays < _maxCycleDays
              ? () => _setCustomLength(_cycleLengthDays + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStartDateField(ThemeData theme) {
    final start = _startDate;
    return OutlinedButton.icon(
      key: const ValueKey('roster-start-date'),
      onPressed: _pickStartDate,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(start == null ? 'Pick a date' : formatFullDate(start)),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildBlocksSection(ThemeData theme) {
    final scheme = theme.colorScheme;
    if (_blocks.isEmpty) {
      return Container(
        key: const ValueKey('roster-blocks-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              'No blocks yet',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Add shift blocks to define your rotation',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _blocks.length; i++)
          _buildBlockTile(theme, i, _blocks[i]),
      ],
    );
  }

  Widget _buildBlockTile(ThemeData theme, int index, PaintedShiftBlock block) {
    final visual = visualFor(block.type);
    final use24Hour = AppPreferences.use24HourOf(context);
    final time = '${formatClock(block.startMinutes, use24Hour: use24Hour)} – '
        '${formatClock(block.endMinutes, use24Hour: use24Hour)}';
    final days = formatDayIndexRanges(block.dayIndices);
    return Card(
      key: ValueKey('roster-block-$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 6,
          height: 40,
          decoration: BoxDecoration(
            color: visual.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text('${shiftTypeLabel(block.type)} · $time'),
        subtitle: Text('Days $days'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('roster-block-edit-$index'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit block',
              onPressed: () => _openBlockSheet(existingIndex: index),
            ),
            IconButton(
              key: ValueKey('roster-block-delete-$index'),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove block',
              onPressed: () => _removeBlock(index),
            ),
          ],
        ),
        onTap: () => _openBlockSheet(existingIndex: index),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('roster-error-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Add Shift Block" paintbrush sheet: pick a type + start/end time, then
/// tap the days of the cycle this block covers. Days already covered by another
/// block are marked with an accent ring — tapping one adds a split shift on
/// that day. If this block's TIME would clash with another block on a shared
/// day, those days turn red and Save is blocked LIVE (not deferred to Create).
/// Returns the composed [PaintedShiftBlock] via `Navigator.pop`, or null on
/// cancel.
class _AddShiftBlockSheet extends StatefulWidget {
  const _AddShiftBlockSheet({
    required this.cycleLength,
    required this.otherBlocks,
    required this.use24Hour,
    this.existing,
  });

  final int cycleLength;

  /// Every block already on the roster except the one being edited — the basis
  /// for both the "shared day" marks and the live time-overlap check.
  final List<PaintedShiftBlock> otherBlocks;
  final bool use24Hour;
  final PaintedShiftBlock? existing;

  @override
  State<_AddShiftBlockSheet> createState() => _AddShiftBlockSheetState();
}

class _AddShiftBlockSheetState extends State<_AddShiftBlockSheet> {
  late ShiftType _type;
  late int _startMinutes;
  late int _endMinutes;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? ShiftType.day;
    _startMinutes = e?.startMinutes ?? 7 * 60;
    _endMinutes = e?.endMinutes ?? 15 * 60;
    _selectedDays = {...?e?.dayIndices};
  }

  /// Days any OTHER block covers — tapping one makes a (possibly valid) split.
  Set<int> get _claimedDays => claimedDayIndices(widget.otherBlocks);

  /// The selected days where THIS block's time clashes with another block —
  /// recomputed every build so it tracks time + day edits live.
  Set<int> get _conflictDays => conflictingPaintedDays(
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        dayIndices: _selectedDays,
        others: widget.otherBlocks,
      );

  bool get _canSave =>
      _selectedDays.isNotEmpty &&
      _startMinutes != _endMinutes &&
      _conflictDays.isEmpty;

  Future<void> _pickTime({required bool start}) async {
    final base = start ? _startMinutes : _endMinutes;
    final picked = await pickPreferredTime(
      context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
    );
    if (!mounted || picked == null) return;
    setState(() {
      final m = picked.hour * 60 + picked.minute;
      if (start) {
        _startMinutes = m;
      } else {
        _endMinutes = m;
      }
    });
  }

  void _toggleDay(int day) {
    // Claimed days are NOT locked — tapping one adds this block as a split on
    // that day. If the times clash the day turns red and Save blocks (see
    // [_conflictDays]); a non-overlapping split is accepted.
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add shift block' : 'Edit shift block',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Off is excluded — an un-painted day is already Off.
              SegmentedButton<ShiftType>(
                key: const ValueKey('block-type'),
                segments: const [
                  ButtonSegment(value: ShiftType.day, label: Text('Day')),
                  ButtonSegment(
                    value: ShiftType.afternoon,
                    label: Text('Afternoon'),
                  ),
                  ButtonSegment(value: ShiftType.night, label: Text('Night')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.single),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('block-start-time'),
                      onPressed: () => _pickTime(start: true),
                      child: Column(
                        children: [
                          Text('Start', style: theme.textTheme.labelSmall),
                          Text(
                            formatClock(_startMinutes,
                                use24Hour: widget.use24Hour),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('block-end-time'),
                      onPressed: () => _pickTime(start: false),
                      child: Column(
                        children: [
                          Text('End', style: theme.textTheme.labelSmall),
                          Text(
                            formatClock(_endMinutes,
                                use24Hour: widget.use24Hour),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap the days this shift covers',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              _buildDayGrid(theme),
              const SizedBox(height: 8),
              if (_conflictDays.isEmpty)
                Text(
                  'Un-tapped days are Off.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                )
              else
                Row(
                  key: const ValueKey('block-conflict-message'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This time overlaps another shift on '
                        'day ${formatDayIndexRanges(_conflictDays)} — '
                        'change the time or those days.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('block-save'),
                onPressed: _canSave
                    ? () => Navigator.of(context).pop(
                          PaintedShiftBlock(
                            type: _type,
                            startMinutes: _startMinutes,
                            endMinutes: _endMinutes,
                            dayIndices: _selectedDays,
                          ),
                        )
                    : null,
                child: Text(
                  widget.existing == null ? 'Add block' : 'Save block',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayGrid(ThemeData theme) {
    final scheme = theme.colorScheme;
    final typeColor = visualFor(_type).color;
    final claimed = _claimedDays;
    final conflicts = _conflictDays;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.cycleLength,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final selected = _selectedDays.contains(i);
        // Covered by ANOTHER block → tapping makes it a split (still tappable).
        final shared = claimed.contains(i);
        // Selected AND time-clashing with another block on that day → illegal.
        final conflict = conflicts.contains(i);
        final Color bg;
        final Color fg;
        if (conflict) {
          bg = scheme.errorContainer;
          fg = scheme.onErrorContainer;
        } else if (selected) {
          bg = typeColor;
          fg = scheme.onPrimary;
        } else {
          bg = scheme.surfaceContainerHigh;
          fg = scheme.onSurface;
        }
        return InkWell(
          key: ValueKey('block-day-$i'),
          onTap: () => _toggleDay(i),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              // A subtle accent ring flags "already has a shift" so the user
              // knows a tap here creates a split; a red border marks a clash.
              border: conflict
                  ? Border.all(color: scheme.error)
                  : (shared && !selected)
                      ? Border.all(color: scheme.primary.withValues(alpha: 0.7))
                      : null,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${i + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                if (shared && !selected && !conflict)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
