import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';
import '../logic/work_history.dart';
import '../state/app_preferences.dart';
import 'shift_format.dart';

/// Signature for the CSV-export side effect. Injected in tests so the share
/// sheet / filesystem are never touched; defaults to [shareWorkHistoryCsv].
typedef WorkHistoryExporter = Future<void> Function(String csv, String filename);

/// **Work History** — the payslip-verification surface (Settings → Work
/// History). Lists the user's completed ad-hoc ("custom") shifts and exports
/// them as a CSV via the native share sheet.
///
/// Reads the full shift box once on open (via [ShiftRepository.getAll]) and
/// filters with [workHistoryShifts] — see that function for the exact scope
/// (completed ad-hoc shifts, archived OR not-yet-archived, OFF days excluded).
/// `getAll` rather than the windowed UI stream so a year-old backfilled shift
/// is never clipped out of the history.
class WorkHistoryScreen extends StatefulWidget {
  const WorkHistoryScreen({super.key, this.exporter});

  /// Test seam — overrides the real share/file export.
  final WorkHistoryExporter? exporter;

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  /// null = still loading; empty = loaded, nothing to show. Sorted oldest →
  /// newest (ledger order); the list is rendered newest-first.
  List<Shift>? _history;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await context.read<ShiftRepository>().getAll();
    if (!mounted) return;
    setState(() => _history = workHistoryShifts(all, now: DateTime.now()));
  }

  Future<void> _export() async {
    final history = _history;
    if (history == null || history.isEmpty || _exporting) return;
    // Capture the messenger before the async gap — BuildContext must not be
    // used across an await.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final csv = workHistoryCsv(history);
      final exporter = widget.exporter ?? shareWorkHistoryCsv;
      await exporter(csv, kWorkHistoryCsvFilename);
      // No success snackbar — the native share sheet IS the confirmation.
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export history: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final canExport = history != null && history.isNotEmpty && !_exporting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work History'),
        actions: [
          IconButton(
            key: const ValueKey('work-history-export'),
            tooltip: 'Export History',
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            onPressed: canExport ? _export : null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: history == null
            ? const Center(child: CircularProgressIndicator())
            : history.isEmpty
                ? const _EmptyHistory()
                : _HistoryList(shifts: history),
      ),
    );
  }
}

/// The completed-shift ledger. Receives the oldest-first list and renders it
/// newest-first (most recently worked shift on top), with a summary header.
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.shifts});

  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    final use24Hour = AppPreferences.use24HourOf(context);
    final newestFirst = shifts.reversed.toList();
    // Worked minutes only — a paused shift contributes 0 to the banner total.
    final totalMinutes =
        shifts.fold<int>(0, (sum, s) => sum + workedMinutes(s));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      // +1 leading row for the summary banner.
      itemCount: newestFirst.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SummaryBanner(
            shiftCount: shifts.length,
            totalMinutes: totalMinutes,
          );
        }
        return _HistoryTile(
          shift: newestFirst[index - 1],
          use24Hour: use24Hour,
        );
      },
    );
  }
}

/// "12 shifts · 96.00 h" banner — the at-a-glance totals a user reconciles
/// against a payslip before exporting.
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.shiftCount, required this.totalMinutes});

  final int shiftCount;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$shiftCount shift${shiftCount == 1 ? '' : 's'} worked',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${formatDecimalHours(totalMinutes)} h',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One completed shift: date, start–end clock window, and decimal hours.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.shift, required this.use24Hour});

  final Shift shift;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = formatClock(shift.startMinutes, use24Hour: use24Hour);
    final end = formatClock(shift.endMinutes, use24Hour: use24Hour);
    final paused = shift.isPaused;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          formatShiftDate(shift.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypeBadge(isAdHoc: shift.isAdHoc),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shift.isOvernight ? '$start – $end (+1)' : '$start – $end',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: paused ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  // Paused → struck time + a Paused badge so the 0.00 h reads as
                  // intentional, not a bug.
                  if (paused) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.do_not_disturb_on_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            shift.pauseReason == null
                                ? 'Paused'
                                : 'Paused · ${shift.pauseReason}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatDecimalHours(workedMinutes(shift))} h',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provenance chip on a history card. Ad-Hoc is accented (safety-orange
/// container) so picked-up overtime pops against the muted, neutral Rotation
/// chip — the at-a-glance "which of these is overtime" the user scans for.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isAdHoc});

  final bool isAdHoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg, fg) = isAdHoc
        ? (
            kAdHocShiftLabel,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          )
        : (
            kRotationShiftLabel,
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.onSurfaceVariant,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No completed shifts yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your worked shifts — rotation and custom alike — appear here '
              'once they finish, ready to export for payslip verification.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Real export: writes [csv] to a temp file named [filename] and hands it to
/// the native share sheet (email, Drive, etc.) via share_plus. Kept as a
/// top-level function (not a method) so it's a clean default for the
/// [WorkHistoryExporter] seam — widget tests inject a fake and never reach the
/// platform channels here.
Future<void> shareWorkHistoryCsv(String csv, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(csv);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Rostrik Work History',
      text: 'My Rostrik work history export.',
    ),
  );
}
