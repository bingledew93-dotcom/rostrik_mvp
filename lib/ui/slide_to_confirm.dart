import 'package:flutter/material.dart';

/// A horizontal slide-to-confirm bar — Rostrik's standard affordance for a
/// state-changing action (visible control → deliberate swipe, never a bare tap
/// that a half-asleep user could trigger by accident). The user drags the
/// handle past [commitFraction] of the track to fire [onConfirm]; releasing
/// short of the threshold springs it back.
///
/// Generalised from the inline `_SlideToConfirmDelete` (alarms list) and
/// `_SlideToDismiss` (wake screen) for the third use site (the Dashboard's
/// "Dismiss Upcoming Alarm"); those two keep their bespoke sizing/copy for now.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.icon = Icons.arrow_forward,
    this.trackColor,
    this.handleColor,
    this.foregroundColor,
    this.trackHeight = 48,
    this.commitFraction = 0.6,
  });

  /// Hint text shown on the track, fading out as the handle advances.
  final String label;

  /// Invoked once when the drag commits past [commitFraction].
  final Future<void> Function() onConfirm;

  final IconData icon;

  /// Track / handle / on-handle colours. Default to the theme's
  /// primaryContainer / primary / onPrimary so the bar reads as an affirmative
  /// (not destructive) action.
  final Color? trackColor;
  final Color? handleColor;
  final Color? foregroundColor;

  final double trackHeight;

  /// Fraction of the track the handle must cross to commit (0..1).
  final double commitFraction;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const double _handleInset = 4;

  double _dragX = 0;
  bool _committed = false;

  void _onUpdate(double maxX, DragUpdateDetails d) {
    if (_committed) return;
    setState(() => _dragX = (_dragX + d.delta.dx).clamp(0.0, maxX));
  }

  Future<void> _onEnd(double maxX) async {
    if (_committed) return;
    if (_dragX >= maxX * widget.commitFraction) {
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
    final trackColor = widget.trackColor ?? theme.colorScheme.primaryContainer;
    final handleColor = widget.handleColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final handleSize = widget.trackHeight - (_handleInset * 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxX = trackWidth - handleSize - (_handleInset * 2);
        final progress = maxX <= 0 ? 0.0 : (_dragX / maxX).clamp(0.0, 1.0);
        return Container(
          height: widget.trackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(widget.trackHeight / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - progress,
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: handleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: fgColor, size: 20),
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
