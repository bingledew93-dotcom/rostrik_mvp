import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/alarm_settings.dart';
import '../data/repositories/alarm_settings_repository.dart';

/// Global alarm-settings screen. Reads via `context.watch<AlarmSettings>()`,
/// writes via `context.read<AlarmSettingsRepository>().write(...)`.
///
/// Deliberately ignorant of the AlarmEngine. The engine subscribes to the
/// settings stream itself and re-reconciles (debounced) on every change —
/// the UI's only job is to land the write.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _LeadTimeSection(),
        ],
      ),
    );
  }
}

class _LeadTimeSection extends StatefulWidget {
  const _LeadTimeSection();

  @override
  State<_LeadTimeSection> createState() => _LeadTimeSectionState();
}

class _LeadTimeSectionState extends State<_LeadTimeSection> {
  // Snaps every 5 min from 0 to 120 → 24 intervals, 25 distinct positions.
  static const _maxMinutes = 120.0;
  static const _divisions = 24;

  /// Local mirror of the slider position during a drag. Null when idle —
  /// in that case we render directly from the watched settings, so an
  /// external write (e.g. another device, a future "reset" button) shows up
  /// immediately. Set on first onChanged of a gesture, cleared on
  /// onChangeEnd after the repo write commits.
  double? _dragMinutes;

  void _commit(double minutes) {
    final settings = AlarmSettings(leadTime: Duration(minutes: minutes.toInt()));
    context.read<AlarmSettingsRepository>().write(settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AlarmSettings>();
    final canonical = settings.leadTime.inMinutes.toDouble();
    final shown = (_dragMinutes ?? canonical).clamp(0.0, _maxMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lead time', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Alarm fires this long before each shift starts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formatLeadTime(shown.toInt()),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: shown,
            min: 0,
            max: _maxMinutes,
            divisions: _divisions,
            label: _formatLeadTime(shown.toInt()),
            onChanged: (v) => setState(() => _dragMinutes = v),
            onChangeEnd: (v) {
              _commit(v);
              setState(() => _dragMinutes = null);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 min', style: theme.textTheme.bodySmall),
              Text('${_maxMinutes.toInt()} min',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatLeadTime(int totalMinutes) {
  if (totalMinutes == 0) return '0 min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}
