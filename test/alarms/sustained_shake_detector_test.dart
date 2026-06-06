import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/sustained_shake_detector.dart';

void main() {
  final t0 = DateTime(2026, 6, 1, 4, 0, 0);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  group('SustainedShakeDetector', () {
    test('sustained above-threshold shaking completes after requiredDuration',
        () {
      final d = SustainedShakeDetector(
        requiredDuration: const Duration(seconds: 3),
        magnitudeThreshold: 12,
      );
      double progress = 0;
      for (var ms = 0; ms <= 3000; ms += 100) {
        progress = d.addSample(20, at(ms));
      }
      expect(progress, 1.0);
      expect(d.isComplete(at(3000)), isTrue);
    });

    test('a single spike cannot complete', () {
      final d = SustainedShakeDetector(
        requiredDuration: const Duration(seconds: 3),
      );
      d.addSample(30, at(0));
      // Then still for a second — the run lapses past the grace window.
      expect(d.addSample(0, at(1000)), 0.0);
    });

    test('sub-threshold troughs within the grace window do NOT reset the run',
        () {
      final d = SustainedShakeDetector(
        requiredDuration: const Duration(seconds: 1),
        magnitudeThreshold: 12,
        graceWindow: const Duration(milliseconds: 350),
      );
      // Above-threshold every 200 ms (gap < grace), troughs in between.
      double progress = 0;
      for (var ms = 0; ms <= 1000; ms += 100) {
        final mag = (ms ~/ 100).isEven ? 20.0 : 2.0;
        progress = d.addSample(mag, at(ms));
      }
      expect(progress, 1.0, reason: 'troughs are tolerated → run survives');
    });

    test('a quiet gap longer than the grace window restarts the run', () {
      final d = SustainedShakeDetector(
        requiredDuration: const Duration(seconds: 3),
        graceWindow: const Duration(milliseconds: 350),
      );
      // Shake for 2s...
      for (var ms = 0; ms <= 2000; ms += 100) {
        d.addSample(20, at(ms));
      }
      // ...go still for ~1s (gap > grace) → run breaks.
      expect(d.addSample(0, at(3000)), 0.0);
      // ...resume; only ~0.5s into the FRESH run, nowhere near complete.
      double progress = 0;
      for (var ms = 3100; ms <= 3500; ms += 100) {
        progress = d.addSample(20, at(ms));
      }
      expect(progress, lessThan(1.0));
    });

    test('reset() forgets the in-progress run', () {
      final d = SustainedShakeDetector(
        requiredDuration: const Duration(seconds: 1),
      );
      d.addSample(20, at(0));
      d.addSample(20, at(500));
      d.reset();
      expect(d.progressAt(at(500)), 0.0);
    });
  });
}
