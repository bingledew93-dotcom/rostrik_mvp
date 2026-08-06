import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/shift_type.dart';
import '../roster_ai/ai_prompts.dart';
import '../roster_ai/roster_ai_parser.dart';
import '../state/app_preferences.dart';
import 'roster/shift_visuals.dart';
import 'shift_format.dart';

/// Called with the confirmed [ParsedShift] list when the user taps "Import
/// Roster". Returns `null` on success, or a human-readable error string (e.g. a
/// clash with the existing roster) which the modal shows inline WITHOUT closing,
/// so the user can adjust and retry. The parent owns persistence; the modal owns
/// its own dismissal (it pops with `true` once [onImport] reports success).
typedef AiImportCallback = Future<String?> Function(List<ParsedShift> shifts);

/// Opens the "Import Roster via AI Bridge" bottom sheet. Resolves to `true` once
/// an import succeeds (the sheet closes itself), or `null` if the user backs out.
Future<bool?> showImportAiModal(
  BuildContext context, {
  required AiImportCallback onImport,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // Sit on the app's raised-surface grey so the sheet reads as part of the
    // dark chassis rather than a floating white card.
    builder: (_) => ImportAiModal(onImport: onImport),
  );
}

/// The AI-bridge import flow, as a self-contained sheet:
///   1. Copy the strict extraction prompt to the clipboard.
///   2. Paste the LLM's reply back in.
///   3. Parse & preview a colour-coded list of the detected shifts.
///   4. Import — hands the parsed list to [onImport] for persistence.
///
/// Pure UI + clipboard; all roster logic lives in [RosterAiParser] and the
/// parent's [onImport]. Themed entirely off `Theme.of(context)` so it inherits
/// Rostrik's pinned dark palette.
class ImportAiModal extends StatefulWidget {
  const ImportAiModal({super.key, required this.onImport});

  final AiImportCallback onImport;

  @override
  State<ImportAiModal> createState() => _ImportAiModalState();
}

class _ImportAiModalState extends State<ImportAiModal> {
  final TextEditingController _responseController = TextEditingController();

  /// Parsed result of the last "Parse & Preview"; null before a successful parse.
  List<ParsedShift>? _parsed;

  /// Inline banner text — a "no shifts detected" parse miss OR an import clash.
  String? _error;

  bool _copied = false;
  bool _importing = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: kRosterAiPromptTemplate));
    if (!mounted) return;
    setState(() => _copied = true);
    // The SnackBar honours the spec's confirmation copy; the inline "Copied"
    // button state is the reliable feedback (a SnackBar can render behind a
    // modal sheet). Reset the button after a beat.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Prompt copied! Paste it into your AI app along with your roster.',
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Nothing to paste from the clipboard.')),
        );
      return;
    }
    setState(() {
      _responseController.text = text;
      // The input changed — any earlier preview/error is now stale.
      _parsed = null;
      _error = null;
    });
  }

  void _parseAndPreview() {
    FocusScope.of(context).unfocus();
    final parsed = RosterAiParser.parseAiOutput(_responseController.text);
    setState(() {
      if (parsed.isEmpty) {
        _parsed = null;
        _error = 'No valid shifts detected. Make sure you used the copied '
            'AI prompt.';
      } else {
        // Chronological order for the preview + the write (import order is
        // irrelevant to persistence, but a sorted preview reads naturally).
        _parsed = [...parsed]..sort((a, b) => a.date.compareTo(b.date));
        _error = null;
      }
    });
  }

  Future<void> _import() async {
    final parsed = _parsed;
    if (parsed == null || parsed.isEmpty || _importing) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    final error = await widget.onImport(parsed);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _importing = false;
        _error = error;
      });
      return;
    }
    // Success — the parent persisted the batch. Close, signalling the caller.
    Navigator.of(context).pop(true);
  }

  /// Tap-to-change cycles a row through the working types (Day → Afternoon →
  /// Night → Day), preserving its clock. Off rows are left alone — a rest day
  /// has no working time to keep, so it isn't part of the cycle.
  static const List<ShiftType> _workingTypeCycle = [
    ShiftType.day,
    ShiftType.afternoon,
    ShiftType.night,
  ];

  void _cycleType(int index) {
    final list = _parsed;
    if (list == null || index < 0 || index >= list.length) return;
    final current = list[index];
    if (current.type == ShiftType.off) return;
    final pos = _workingTypeCycle.indexOf(current.type);
    final next = _workingTypeCycle[(pos + 1) % _workingTypeCycle.length];
    final updated = [...list];
    updated[index] = current.withType(next);
    setState(() => _parsed = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parsed = _parsed;
    // Cap the sheet so a long preview scrolls internally rather than shoving the
    // Import button off-screen; leave room for the status bar.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(theme),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _stepLabel(theme, '1', 'Copy the prompt'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('import-ai-copy-prompt'),
                        onPressed: _copyPrompt,
                        icon: Icon(
                          _copied ? Icons.check_circle_outline : Icons.copy,
                          size: 18,
                        ),
                        label: Text(_copied ? 'Copied!' : 'Copy AI Prompt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor:
                              _copied ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste it into ChatGPT, Gemini or any AI app, then add '
                        'your roster text or a photo/screenshot and send.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _stepLabel(theme, '2', "Paste the AI's reply"),
                          ),
                          TextButton.icon(
                            key: const ValueKey('import-ai-paste'),
                            onPressed: _paste,
                            icon: const Icon(Icons.content_paste, size: 18),
                            label: const Text('Paste'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('import-ai-response-field'),
                        controller: _responseController,
                        minLines: 4,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        onChanged: (_) {
                          // Typing invalidates the previous preview/error.
                          if (_parsed != null || _error != null) {
                            setState(() {
                              _parsed = null;
                              _error = null;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          hintText:
                              '10/08/2026 | Day | 06:00 - 18:00\n11/08/2026 | '
                              'Off | 00:00 - 00:00',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('import-ai-parse'),
                        onPressed: _parseAndPreview,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Parse & Preview'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _errorBanner(theme, _error!),
                      ],
                      if (parsed != null && parsed.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _stepLabel(theme, '3', 'Review the detected shifts'),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a badge to switch it between Day, Afternoon and '
                          'Night if the AI got one wrong.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        _PreviewList(shifts: parsed, onCycleType: _cycleType),
                      ],
                    ],
                  ),
                ),
              ),
              if (parsed != null && parsed.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('import-ai-import'),
                  onPressed: _importing ? null : _import,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: _importing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Import ${parsed.length} '
                          'day${parsed.length == 1 ? '' : 's'}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import via AI',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Turn any roster text into shifts with the help of an AI app.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('import-ai-close'),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _stepLabel(ThemeData theme, String number, String text) {
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _errorBanner(ThemeData theme, String message) {
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('import-ai-error'),
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

/// The colour-coded preview: one row per detected day, capped-height and
/// internally scrollable so a long roster doesn't blow out the sheet. Day =
/// amber, Night = indigo, Off = grey, reusing the app-wide [visualFor] palette
/// so the badges match the calendar and timeline.
class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.shifts, required this.onCycleType});

  final List<ParsedShift> shifts;

  /// Cycles the working type of the row at the given index (Off rows never
  /// call it — they're passed a null tap handler).
  final void Function(int index) onCycleType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final working = shifts.where((s) => s.type != ShiftType.off).length;
    final off = shifts.length - working;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.event_available_outlined,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${shifts.length} day${shifts.length == 1 ? '' : 's'} '
                    '· $working working · $off off',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              key: const ValueKey('import-ai-preview'),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: shifts.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              itemBuilder: (_, i) => _PreviewRow(
                shift: shifts[i],
                // Off is a rest day — not part of the tap-to-change cycle.
                onChangeType: shifts[i].type == ShiftType.off
                    ? null
                    : () => onCycleType(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.shift, this.onChangeType});

  final ParsedShift shift;

  /// Non-null for working rows — tapping the type badge cycles Day/Afternoon/
  /// Night. Null for Off rows, whose badge is inert.
  final VoidCallback? onChangeType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = shift.type;
    final isOff = type == ShiftType.off;
    final use24Hour = AppPreferences.use24HourOf(context);
    final timeLabel = isOff
        ? 'Rest day'
        : '${formatClock(shift.startMinutes, use24Hour: use24Hour)} – '
            '${formatClock(shift.endMinutes, use24Hour: use24Hour)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _TypeBadge(type: type, onTap: onChangeType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatShiftDate(shift.date),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill badge tinted with the shift type's palette colour — Yellow (Day),
/// Orange (Afternoon), Blue/indigo (Night), Grey (Off). When [onTap] is set the
/// badge is tappable (working rows) and shows a small ⇕ affordance so it reads
/// as "tap to change"; tapping cycles Day → Afternoon → Night.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, this.onTap});

  final ShiftType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(type);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visual.color.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 14, color: visual.color),
          const SizedBox(width: 5),
          Text(
            shiftTypeShortLabel(type),
            style: theme.textTheme.labelMedium?.copyWith(
              color: visual.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.unfold_more, size: 13, color: visual.color),
          ],
        ],
      ),
    );
    if (onTap == null) return badge;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: badge,
    );
  }
}
