import 'package:flutter/material.dart';

import '../data/models/shift_pattern.dart';
import '../data/models/shift_type.dart';
import 'roster/shift_visuals.dart';
import 'roster_config_screen.dart';
import 'template_screen.dart';

/// Opens the dark-themed "New Shift Roster" bottom sheet.
Future<void> showNewRosterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NewRosterSheet(),
  );
}

const _kSheetBg = Color(0xFF1A1C23);
const _kCardBg = Color(0xFF24262E);
const _kOffBarColor = Color(0xFF3A3C47);

class _NewRosterSheet extends StatelessWidget {
  const _NewRosterSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(onClose: () => Navigator.of(context).pop()),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'CHOOSE A PATTERN',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                ...kShiftPatterns.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PatternCard(pattern: p),
                  ),
                ),
                const SizedBox(height: 8),
                const _CustomRosterTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Shift Roster',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  'Set up your shift rotation pattern',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final ShiftPattern pattern;

  void _open(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => RosterConfigScreen(pattern: pattern),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pattern.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pattern.cycleDays}-day cycle',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PatternBar(segments: pattern.segments),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PatternBar extends StatelessWidget {
  const _PatternBar({required this.segments});

  final List<PatternSegment> segments;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: segments.map((s) {
            final color = s.type == ShiftType.off
                ? _kOffBarColor
                : visualFor(s.type).color.withValues(alpha: 0.9);
            return Expanded(
              flex: s.days,
              child: ColoredBox(color: color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CustomRosterTile extends StatelessWidget {
  const _CustomRosterTile();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final nav = Navigator.of(context);
        nav.pop();
        nav.push(MaterialPageRoute(
          builder: (_) => const TemplateScreen(),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.tune, color: Colors.white60, size: 22),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build custom roster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Doesn't fit a preset? Compose your own blocks.",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
