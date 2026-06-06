import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift_type.dart';
import '../logic/shift_block.dart';
import '../logic/shift_generator.dart';
import '../state/draft_roster_controller.dart';
import 'roster/shift_visuals.dart';
import '../state/app_preferences.dart';
import 'shift_format.dart';

/// Human-in-the-Loop review of a freshly scanned roster.
///
/// The screen is a pure consumer of [DraftRosterController]: it renders the
/// in-memory draft and forwards taps, holding no roster logic itself. The draft
/// is persisted only when the user taps **Confirm & Save** (and the generator
/// accepts it) — backing out discards it for free, since nothing is written
/// until [DraftRosterController.commit].
///
/// Three correction affordances, matching the asymmetric "phantom is cheap,
/// dropped is expensive" cost model the sanitizer assumes:
///   * **Swipe-to-delete + Undo** — removing a phantom row is one gesture; the
///     visible delete background and the Undo SnackBar keep it discoverable and
///     reversible (never a long-press, never a confirm dialog for an
///     uncommitted draft).
///   * **One-tap type row** — a permanently visible [ Day | Afternoon | Night |
///     Off ] selector on every card; a single tap reassigns the type. No menu,
///     no extra tap — built for a user coming off a 12-hour shift.
///   * **Tap the time** — the standard time picker fixes a scanned-without-end
///     row; Confirm stays disabled until every such row is resolved.
class DraftRosterReviewScreen extends StatelessWidget {
  const DraftRosterReviewScreen({
    super.key,
    required this.anchorDate,
    required this.blocks,
    this.sourceImage,
    this.label = 'Scanned roster',
    this.controller,
  });

  /// Local date the scanned sequence starts on; row N is `anchorDate + N`.
  final DateTime anchorDate;

  /// Generator-ready blocks (already mapped from OCR space via
  /// [ScannedRosterInjection.map]); one per scanned day, in reading order.
  final List<ShiftBlock> blocks;

  /// Cropped scan for the reference panel (compressed JPEG), or null.
  final Uint8List? sourceImage;

  final String label;

  /// Injectable for tests/previews. In production the screen builds its own
  /// controller from the [ShiftGenerator] in the provider tree.
  final DraftRosterController? controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DraftRosterController>(
      create: (ctx) =>
          controller ??
          DraftRosterController(
            generator: ctx.read<ShiftGenerator>(),
            anchorDate: anchorDate,
            initialBlocks: blocks,
            sourceImage: sourceImage,
            label: label,
          ),
      child: const _DraftRosterReviewView(),
    );
  }
}

class _DraftRosterReviewView extends StatefulWidget {
  const _DraftRosterReviewView();

  @override
  State<_DraftRosterReviewView> createState() => _DraftRosterReviewViewState();
}

class _DraftRosterReviewViewState extends State<_DraftRosterReviewView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<DraftRosterController>();
    _nameController = TextEditingController(text: controller.label);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index, {required bool start}) async {
    final controller = context.read<DraftRosterController>();
    final block = controller.days[index].block;
    final current = start ? block.startMinutes : block.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (start) {
      controller.setStartMinutes(index, minutes);
    } else {
      controller.setEndMinutes(index, minutes);
    }
  }

  void _delete(int index, DraftDay day) {
    final controller = context.read<DraftRosterController>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = controller.removeAt(index);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${formatShiftDate(day.date)}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.insertAt(removed.index, removed.block),
        ),
      ),
    );
  }

  Future<void> _commit() async {
    final controller = context.read<DraftRosterController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final count = controller.dayCount;

    final ok = await controller.commit();
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Saved $count days to your roster')),
      );
      // pop(true) mirrors CustomBuilderScreen's contract so the pattern picker
      // fires its onGenerated after a scan round-trip.
      navigator.pop(true);
    }
    // On failure the controller exposes commitError; the banner below renders
    // it reactively, so there's nothing to do here.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<DraftRosterController>();
    final days = controller.days;

    return Scaffold(
      appBar: AppBar(title: const Text('Review scanned roster')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  if (controller.sourceImage != null) ...[
                    _ImageReferencePanel(bytes: controller.sourceImage!),
                    const SizedBox(height: 16),
                  ],
                  Text('Roster name', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. May roster',
                    ),
                    onChanged: controller.setLabel,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${days.length} day${days.length == 1 ? '' : 's'} from '
                    '${formatShiftDate(controller.anchorDate)}. Swipe a row to '
                    'remove it; tap its type or time to fix it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.attentionCount > 0) ...[
                    _AttentionBanner(count: controller.attentionCount),
                    const SizedBox(height: 12),
                  ],
                  for (final (index, day) in days.indexed)
                    _DraftDayRow(
                      key: ValueKey('draft-day-${day.id}'),
                      day: day,
                      onTypeChanged: (t) => controller.setType(index, t),
                      onPickStartTime: () => _pickTime(index, start: true),
                      onPickEndTime: () => _pickTime(index, start: false),
                      onDelete: () => _delete(index, day),
                    ),
                  if (controller.commitError != null) ...[
                    const SizedBox(height: 4),
                    _CommitErrorBanner(message: controller.commitError!),
                  ],
                ],
              ),
            ),
            _BottomBar(
              canCommit: controller.canCommit,
              isCommitting: controller.isCommitting,
              onCommit: _commit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible reference panel: a thumbnail of the cropped scan that expands to
/// a pan/zoom viewer so the user can cross-check the parsed list against the
/// source. `cacheWidth` caps the decode size — the bytes are bounded by
/// `kMaxScanEdgePx` but we never need full-res for a thumbnail.
class _ImageReferencePanel extends StatelessWidget {
  const _ImageReferencePanel({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.image_outlined),
        title: const Text('Scanned image'),
        subtitle: const Text('Tap the image to enlarge and compare'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          InkWell(
            onTap: () => _showFullScreen(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.memory(
                bytes,
                cacheWidth: 1000,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Could not display the scanned image.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.memory(bytes)),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One reviewable day: date, a tappable type chip, and (for working shifts) the
/// start→end time. Dumb — every mutation is a callback the screen handles, so
/// the row holds no controller reference.
class _DraftDayRow extends StatelessWidget {
  const _DraftDayRow({
    super.key,
    required this.day,
    required this.onTypeChanged,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onDelete,
  });

  final DraftDay day;
  final ValueChanged<ShiftType> onTypeChanged;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = day.block;
    final isOff = block.type == ShiftType.off;

    return Dismissible(
      key: ValueKey('dismiss-${day.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              'Remove',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatShiftDate(day.date),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _TypeSelector(selected: block.type, onChanged: onTypeChanged),
              if (!isOff) ...[
                const SizedBox(height: 8),
                _TimeRow(
                  startMinutes: block.startMinutes,
                  endMinutes: block.endMinutes,
                  needsEndTime: day.needsEndTime,
                  onPickStartTime: onPickStartTime,
                  onPickEndTime: onPickEndTime,
                ),
                if (day.needsEndTime) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Scanned without an end time — set it to enable Save.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The one-tap shift-type selector: a permanently visible row of all four types
/// on every card. No menu, no extra tap — a single tap commits the change to
/// the draft. Each option keeps its shared [visualFor] colour so a tired user
/// recognises it at a glance; selection adds a filled tint, a thicker coloured
/// border, and bold text.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final ShiftType selected;
  final ValueChanged<ShiftType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in ShiftType.values)
          Expanded(
            child: _TypeOption(
              type: type,
              selected: type == selected,
              onTap: () => onChanged(type),
            ),
          ),
      ],
    );
  }
}

/// A single segment of [_TypeSelector]. The icon is stacked over the label so
/// the long "Afternoon" word still fits four-across on a narrow phone (iPhone
/// SE / Samsung A15); a [FittedBox] is the final safety net against overflow.
class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ShiftType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(type);
    final textColor =
        selected ? visual.color : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? visual.color.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? visual.color : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(visual.icon, color: visual.color, size: 22),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shiftTypeLabel(type),
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Start→end time, mirroring the custom builder: tap a value to open the time
/// picker; the end shows a red "Set end" when the scan left it blank.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.startMinutes,
    required this.endMinutes,
    required this.needsEndTime,
    required this.onPickStartTime,
    required this.onPickEndTime,
  });

  final int startMinutes;
  final int endMinutes;
  final bool needsEndTime;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final use24Hour = AppPreferences.use24HourOf(context);
    return Row(
      children: [
        Expanded(child: Text('Time', style: theme.textTheme.bodyLarge)),
        OutlinedButton(
          onPressed: onPickStartTime,
          child: Text(formatClock(startMinutes, use24Hour: use24Hour)),
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
          onPressed: onPickEndTime,
          style: needsEndTime
              ? OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                )
              : null,
          child: Text(
            needsEndTime
                ? 'Set end'
                : formatClock(endMinutes, use24Hour: use24Hour),
          ),
        ),
      ],
    );
  }
}

/// "Finish this" banner (tertiary, not error) shown while rows still need an
/// end time — same visual language as the custom builder's incomplete banner.
class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule_outlined,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 1
                  ? '1 day was scanned without an end time. Tap its time to set '
                      'it before saving.'
                  : '$count days were scanned without an end time. Tap each '
                      'time to set it before saving.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red banner for the generator's rejection (structural error / time overlap),
/// rendered above the Save button so a multi-line overlap report wraps cleanly.
class _CommitErrorBanner extends StatelessWidget {
  const _CommitErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned bottom action bar holding the single commit button. Kept out of the
/// scrolling list so "Confirm & Save" is always reachable.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canCommit,
    required this.isCommitting,
    required this.onCommit,
  });

  final bool canCommit;
  final bool isCommitting;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: FilledButton(
          onPressed: canCommit ? onCommit : null,
          child: isCommitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm & Save'),
        ),
      ),
    );
  }
}
