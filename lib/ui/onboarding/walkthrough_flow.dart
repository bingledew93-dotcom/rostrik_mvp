import 'package:flutter/material.dart';

import '../../data/models/shift_type.dart';
import '../app_theme.dart';
import '../critical_dismiss_controls.dart';
import '../roster/shift_visuals.dart';

/// The Phase-4 interactive walkthrough: a brief, skippable tour that teaches the
/// two gestures that make Rostrik click — **painting a roster** (the shift-block
/// painter) and the **sustained shake** that dismisses a Critical-Shift alarm.
///
/// Deliberately self-contained and side-effect-free: the painter lesson is a
/// throwaway practice grid (no roster/Hive writes), and the shake lesson reuses
/// the real [ShakeToDismiss] widget so the user practises the exact gesture the
/// wake screen uses — but here it just lights up a "You've got it" state.
///
/// One [onFinish] callback covers every exit (the close ✕, "Skip", and the final
/// "Done"), so the same widget drops into first-launch onboarding (where
/// [onFinish] steps the flow forward) AND a Settings replay (where it pops the
/// pushed route). The shake stream/clock are injectable for deterministic
/// widget tests, mirroring [ShakeToDismiss].
class WalkthroughFlow extends StatefulWidget {
  const WalkthroughFlow({
    super.key,
    required this.onFinish,
    this.shakeMagnitudeStream,
    this.shakeClock,
  });

  /// Called on any exit — the ✕/Skip affordance and the final Done button.
  /// Onboarding wires this to "advance"; a Settings replay wires it to "pop".
  final VoidCallback onFinish;

  /// Forwarded to [ShakeToDismiss] — injected so tests drive the shake lesson
  /// without a device.
  final Stream<double>? shakeMagnitudeStream;
  final DateTime Function()? shakeClock;

  @override
  State<WalkthroughFlow> createState() => _WalkthroughFlowState();
}

class _WalkthroughFlowState extends State<WalkthroughFlow> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pageCount = 4;

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      widget.onFinish();
      return;
    }
    _goTo(_page + 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: page dots + a close/skip affordance (both exit the tour).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  _PageDots(count: _pageCount, active: _page),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('walkthrough-skip'),
                    onPressed: widget.onFinish,
                    child: Text(isLast ? 'Close' : 'Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  const _IntroPage(),
                  const _PainterPracticePage(),
                  _ShakePracticePage(
                    magnitudeStream: widget.shakeMagnitudeStream,
                    clock: widget.shakeClock,
                  ),
                  const _DonePage(),
                ],
              ),
            ),
            // Bottom nav: Back (past the first page) + primary Next/Done.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      key: const ValueKey('walkthrough-back'),
                      onPressed: () => _goTo(_page - 1),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    width: 160,
                    child: FilledButton(
                      key: ValueKey(
                        isLast ? 'walkthrough-done' : 'walkthrough-next',
                      ),
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(isLast ? 'Done' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared page scaffold: centred icon, title, body, and an optional interactive
/// slot below.
class _LessonPage extends StatelessWidget {
  const _LessonPage({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Icon(icon, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 28),
            child!,
          ],
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LessonPage(
      icon: Icons.waving_hand_outlined,
      title: 'A 60-second tour',
      body: 'Two things that make Rostrik click. You can skip anytime.',
      child: Column(
        children: [
          _FeatureRow(
            icon: Icons.brush_outlined,
            label: 'Paint your roster',
            detail: 'Tap the days you work — that fast.',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.vibration,
            label: 'Shake to dismiss',
            detail: 'A firm shake switches off a critical alarm.',
          ),
          const SizedBox(height: 4),
          Text(
            'Tap Next to try each one.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive practice grid — a throwaway week the user paints on to learn the
/// gesture. No data leaves this widget.
class _PainterPracticePage extends StatefulWidget {
  const _PainterPracticePage();

  @override
  State<_PainterPracticePage> createState() => _PainterPracticePageState();
}

class _PainterPracticePageState extends State<_PainterPracticePage> {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final Set<int> _painted = {};

  void _toggle(int i) => setState(() {
        _painted.contains(i) ? _painted.remove(i) : _painted.add(i);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayColor = visualFor(ShiftType.day).color;
    final count = _painted.length;
    final feedback = count == 0
        ? 'Tap a day to paint a Day shift onto it.'
        : 'Nice! ${count == 1 ? 'That day is' : 'Those $count days are'} a '
            'Day block. Untapped days stay Off — that easy.';

    return _LessonPage(
      icon: Icons.brush_outlined,
      title: 'Paint your roster',
      body: 'Tap the days you work. In the real builder you can add more '
          'blocks (afternoons, nights) the same way.',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _labels.length; i++)
                _PracticeCell(
                  key: ValueKey('practice-day-$i'),
                  label: _labels[i],
                  painted: _painted.contains(i),
                  color: dayColor,
                  onTap: () => _toggle(i),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            feedback,
            key: const ValueKey('practice-feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: count == 0
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
              fontWeight: count == 0 ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeCell extends StatelessWidget {
  const _PracticeCell({
    super.key,
    required this.label,
    required this.painted,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool painted;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 52,
        decoration: BoxDecoration(
          color: painted
              ? color.withValues(alpha: 0.9)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: painted ? color : theme.colorScheme.outlineVariant,
            width: painted ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: painted ? Colors.black : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Shake practice — reuses the real [ShakeToDismiss]; on completion it swaps to
/// a success state instead of dismissing anything.
class _ShakePracticePage extends StatefulWidget {
  const _ShakePracticePage({this.magnitudeStream, this.clock});

  final Stream<double>? magnitudeStream;
  final DateTime Function()? clock;

  @override
  State<_ShakePracticePage> createState() => _ShakePracticePageState();
}

class _ShakePracticePageState extends State<_ShakePracticePage> {
  bool _done = false;

  Future<void> _onShaken() async {
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LessonPage(
      icon: Icons.vibration,
      title: 'Shake to dismiss',
      body: 'Critical-Shift alarms need a firm, steady shake to switch off, so '
          'a half-asleep tap can’t. Give it a go — shake your phone.',
      child: _done
          ? Container(
              key: const ValueKey('shake-success'),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'You’ve got it!',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'That’s exactly how you’ll silence a critical alarm.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              // The shake demo reuses the real alarm's white-on-translucent
              // pill, which is styled for the always-dark alarm screen. Give it
              // a dark backing so it reads correctly (and previews the real
              // surface) even when the app is in the cream light theme.
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kRostrikBlack,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ShakeToDismiss(
                onDismissed: _onShaken,
                magnitudeStream: widget.magnitudeStream,
                clock: widget.clock,
              ),
            ),
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage();

  @override
  Widget build(BuildContext context) {
    return const _LessonPage(
      icon: Icons.check_circle_outline,
      title: 'You’re all set',
      body: 'Build a roster anytime from Manage, and revisit this tour from '
          'Settings → Help whenever you like.',
    );
  }
}
