import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/app_alarm.dart';
import '../data/repositories/app_alarm_repository.dart';
import 'create_alarm_sheet.dart';
import 'shift_format.dart';

/// The Alarms room — tab 2 of the MainLayout chassis. Currently a
/// read + toggle surface; the create / edit flow lands in the next
/// phase ("the complex bundle logic"), so the FAB shows a placeholder
/// dialog and no widget here mutates beyond flipping `enabled`.
///
/// Source of truth: `context.watch<List<AppAlarm>>()` from `AppProviders`,
/// which streams the `alarms` Hive box.
class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarms = context.watch<List<AppAlarm>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      // SafeArea(top: false) — AppBar already consumes the status-bar
      // inset; bottom matters so the list and FAB don't tuck under the
      // gesture pill / 3-button bar on edge-to-edge displays.
      body: SafeArea(
        top: false,
        child: alarms.isEmpty
            ? const _EmptyState()
            : _AlarmList(alarms: alarms),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('alarms-add-fab'),
        // See RosterScreen for the rationale — IndexedStack keeps
        // both FABs alive at once; nulling the heroTag breaks the
        // default-tag collision without affecting the tap behaviour.
        heroTag: null,
        onPressed: () => showCreateAlarmSheet(context),
        tooltip: 'Add alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No alarms yet.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmList extends StatelessWidget {
  const _AlarmList({required this.alarms});

  final List<AppAlarm> alarms;

  @override
  Widget build(BuildContext context) {
    // Sort by time-of-day so the visible order is stable and useful —
    // earliest alarm at the top. Repo gives us no ordering guarantee,
    // so the UI sorts on display.
    final sorted = [...alarms]
      ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _AlarmCard(
        key: ValueKey('alarm-card-${sorted[i].id}'),
        alarm: sorted[i],
      ),
    );
  }
}

class _AlarmCard extends StatefulWidget {
  const _AlarmCard({super.key, required this.alarm});

  final AppAlarm alarm;

  @override
  State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard> {
  bool _confirming = false;

  Future<void> _onConfirmDelete() async {
    // Snapshot the repo before the await — the stream-driven rebuild
    // will drop this card from the list as soon as delete resolves,
    // and reading context post-await would race with disposal.
    final repo = context.read<AppAlarmRepository>();
    await repo.delete(widget.alarm.id);
  }

  void _onCancel() {
    if (!mounted) return;
    setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarm = widget.alarm;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: _confirming
            ? _buildConfirmingRow(theme)
            : _buildNormalRow(context, theme, alarm),
      ),
    );
  }

  Widget _buildNormalRow(
    BuildContext context,
    ThemeData theme,
    AppAlarm alarm,
  ) {
    final fadedWhenOff = alarm.enabled ? 1.0 : 0.55;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Opacity(
            opacity: fadedWhenOff,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatHhmm(alarm.minutesOfDay),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alarm.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _repeatLabel(alarm.repeatType),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        Switch.adaptive(
          value: alarm.enabled,
          onChanged: (v) => context
              .read<AppAlarmRepository>()
              .upsert(alarm.copyWith(enabled: v)),
        ),
        IconButton(
          key: ValueKey('alarm-delete-icon-${alarm.id}'),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: () => setState(() => _confirming = true),
        ),
      ],
    );
  }

  Widget _buildConfirmingRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _SlideToConfirmDelete(onConfirm: _onConfirmDelete),
        ),
        IconButton(
          key: ValueKey('alarm-delete-cancel-${widget.alarm.id}'),
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: _onCancel,
        ),
      ],
    );
  }
}

/// Compact slide-to-confirm bar — the in-place confirmation affordance
/// per Rostrik's UX standard (visible icon → swipe-to-confirm) for
/// destructive actions. Modelled on `_SlideToDismiss` in
/// `wake_up_screen.dart` but sized for a list-row context; intentionally
/// not yet extracted to a shared widget (the two contexts have different
/// dimensions and copy — extract on the third use case).
class _SlideToConfirmDelete extends StatefulWidget {
  const _SlideToConfirmDelete({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_SlideToConfirmDelete> createState() => _SlideToConfirmDeleteState();
}

class _SlideToConfirmDeleteState extends State<_SlideToConfirmDelete> {
  static const double _trackHeight = 44;
  static const double _handleSize = 36;
  static const double _handleInset = 4;
  static const double _commitFraction = 0.6;

  double _dragX = 0;
  bool _committed = false;

  void _onUpdate(double maxX, DragUpdateDetails d) {
    if (_committed) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, maxX);
    });
  }

  Future<void> _onEnd(double maxX) async {
    if (_committed) return;
    if (_dragX >= maxX * _commitFraction) {
      _committed = true;
      setState(() => _dragX = maxX);
      await widget.onConfirm();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxX = trackWidth - _handleSize - (_handleInset * 2);
        final progress = maxX <= 0 ? 0.0 : (_dragX / maxX).clamp(0.0, 1.0);
        return Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(_trackHeight / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - progress,
                child: Text(
                  'Swipe to delete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: _handleInset + _dragX,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => _onUpdate(maxX, d),
                  onHorizontalDragEnd: (_) => _onEnd(maxX),
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onError,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Display copy for the [AppAlarmRepeatType] enum. Kept in the UI layer
/// so the model file stays data-only — the user can re-word these
/// strings without touching the persistence schema.
String _repeatLabel(AppAlarmRepeatType type) {
  switch (type) {
    case AppAlarmRepeatType.followsRotation:
      return 'Follows your rotation';
    case AppAlarmRepeatType.oneTime:
      return 'Rings one time only';
  }
}
