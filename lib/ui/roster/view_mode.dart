import 'package:flutter/material.dart';

/// Which projection of the roster the user is currently looking at.
/// Pure UI state — never persisted, never read by the engine.
enum ViewMode { timeline, calendar }

/// Segmented switch above the roster body. M3 SegmentedButton matches
/// the platform idiom for a binary view toggle and gives generous
/// tap targets for the panic-button shift-worker context.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ViewMode value;
  final ValueChanged<ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<ViewMode>(
        segments: const [
          ButtonSegment(
            value: ViewMode.timeline,
            label: Text('Timeline'),
            icon: Icon(Icons.view_list_outlined),
          ),
          ButtonSegment(
            value: ViewMode.calendar,
            label: Text('Calendar'),
            icon: Icon(Icons.calendar_view_month_outlined),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
