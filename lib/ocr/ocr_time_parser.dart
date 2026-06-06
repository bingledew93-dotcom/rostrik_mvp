import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';
import 'shift_block.dart';

/// Converts the chaotic raw text Google ML Kit reads off a roster photo into a
/// clean [ShiftBlock] of `minuteOfDay` integers.
///
/// **Pure Dart by design** — this file never imports
/// `google_mlkit_text_recognition`. ML Kit produces the raw string upstream;
/// the parser only consumes strings, so the whole gauntlet unit-tests on the
/// Dart VM with zero platform channels.
///
/// Pipeline (first stage that yields a result wins):
///   1. **Pre-scrub failsafe** ([preScrub]) — fix the common OCR letter↔digit
///      confusions and squash spacing, producing the "time path" string.
///   2. **Range** — `0600-1800`, `6am-6pm`: two times → start + end.
///   3. **Single time** — the 24h then 12h tiers → start only (end null).
///   4. **Grid-letter fallback** — a lone D/N/A/O (or a bare `0` from a
///      handwritten 'O' that ML Kit misread as a zero) → a standard shift block.
/// Returns `null` only when nothing usable is found.
///
/// Note on tier ordering: the 12h tier is consulted before the 24h tier
/// **when an am/pm modifier is present** — otherwise a colon+pm string like
/// `6:00pm` would be mis-read as 24h `06:00` by the 24h pattern. Pure-numeric
/// strings carry no am/pm, so they fall straight through to the 24h tier.
class OcrTimeParser {
  OcrTimeParser._();

  // --- Tier 1: 24-hour. Hour 00–23 (`[01]?\d` covers 0–19, `2[0-3]` 20–23),
  //     optional colon, minute 00–59. Digit boundaries stop it from biting
  //     into a longer run (so `2400` / `2500` correctly fail to match).
  static final RegExp _tier24h =
      RegExp(r'(?<!\d)([01]?\d|2[0-3])[:.]?([0-5]\d)(?!\d)');

  // --- Tier 2: 12-hour. Hour 1–12, optional minutes (colon OR dot), am/pm with
  //     tolerant dots/spaces (`6am`, `6:00am`, `9.15am`, `6 a.m.`, `12pm`).
  //     The trailing `m` is fuzzed to `[mnr]` because handwriting makes ML Kit
  //     mis-read `pm` as `pn`/`pr` (and `p.m.` collapses to the same shape) —
  //     the `[ap]` arm still fixes am-vs-pm, only the final letter is forgiven.
  //     A `(?![a-z])` boundary keeps that forgiveness honest: the fuzzy letter
  //     must END the token, so a real word like `printer` (`...pr` + `inter`)
  //     can never be mistaken for `pr`→`pm`.
  static final RegExp _tier12h = RegExp(
    r'(?<!\d)(1[0-2]|0?[1-9])(?:[:.]?([0-5]\d))?\s*([ap])\s*\.?\s*[mnr]\.?(?![a-z])',
  );

  // --- Cheap presence test for an am/pm modifier, used to decide tier order.
  //     Mirrors the fuzzed trailing letter above so a colon+`pn` string like
  //     `6:30pn` is still routed to the 12h tier first (else it mis-reads as
  //     24h `06:30`).
  static final RegExp _hasAmPm = RegExp(r'[ap]\s*\.?\s*[mnr]');

  // --- Range separators: hyphen family, tilde, slash, equals, or the word
  //     "to". `=` is here because shift workers label cells `D = 0600-1400`
  //     (and ML Kit sometimes renders a dash as `=`).
  static final RegExp _rangeSep = RegExp(r'\s*(?:[-–—~/=]|\bto\b)\s*');

  // --- Combined any-time matcher used by [findTimes]: the 12h arm (groups
  //     1-3) OR the 24h arm (groups 4-5). 12h is listed first so a colon+pm
  //     token like `6:00pm` takes the 12h arm. The (?<!\d)/(?!\d) digit guards
  //     keep it from biting into a phone number / employee id — a free bit of
  //     retail-noise rejection.
  //     The 12h arm carries the same fuzzed trailing letter + boundary guard as
  //     [_tier12h] so a column like `0600 3pn` finds both times.
  static final RegExp _anyTime = RegExp(
    r'(?<!\d)(1[0-2]|0?[1-9])(?:[:.]?([0-5]\d))?\s*([ap])\s*\.?\s*[mnr]\.?(?![a-z])'
    r'|'
    r'(?<!\d)([01]?\d|2[0-3])[:.]?([0-5]\d)(?!\d)',
  );

  /// Decodes one roster cell. See class docs for the staged pipeline.
  static ShiftBlock? parse(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Both the letter fallback and the range split work off `lower` (NOT the
    // scrubbed string): the fallback so a lone 'O' survives as the Off letter
    // rather than being mapped to '0', and the range split so its `to`
    // separator isn't itself corrupted into `t0` by the o→0 scrub.
    return _tryRange(lower) ??
        _trySingleTime(preScrub(lower)) ??
        _tier3Letter(lower);
  }

  /// Decodes one line that represents a single shift's *range* — start → end.
  /// A range shows up two ways:
  ///   1. an explicit separator (`9am-5pm`, `9am to 5pm`, `0600~1800`) — handled
  ///      by [_tryRange];
  ///   2. **exactly two time tokens** with only whitespace (or nothing) between
  ///      them (`9:15am  5:30pm`, `0600 1800`) — the column layout that was
  ///      silently dropping every end time.
  ///
  /// Anything else (zero, one, or three-plus times) returns null so the caller
  /// can fall back to single-time / per-cell parsing.
  static ShiftBlock? parseRange(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.isEmpty) return null;
    final explicit = _tryRange(lower);
    if (explicit != null) return explicit;
    final times = findTimes(lower);
    if (times.length == 2) {
      return ShiftBlock(startMinutes: times[0], endMinutes: times[1]);
    }
    return null;
  }

  /// Step 1 failsafe. Assumes [lowered] is already lower-cased + trimmed.
  /// Applied to the time path only.
  ///
  ///   * `o` → `0`
  ///   * `l` → `1` and `i` → `1` — lower-casing has already folded `I` → `i`,
  ///     so mapping BOTH `l` and `i` is what realises the spec's "l / I → 1".
  ///   * whitespace BETWEEN digits is removed (`0 6 0 0` → `0600`), iterated
  ///     to a fixed point so a run of spaced digits fully closes up (a single
  ///     pass consumes the right-hand digit and would skip the next gap).
  @visibleForTesting
  static String preScrub(String lowered) {
    var s =
        lowered.replaceAll('o', '0').replaceAll('l', '1').replaceAll('i', '1');
    final interDigit = RegExp(r'(\d)\s+(\d)');
    String prev;
    do {
      prev = s;
      s = s.replaceAllMapped(interDigit, (m) => '${m[1]}${m[2]}');
    } while (s != prev);
    return s;
  }

  /// Letter→digit confusions only (`o`→`0`, `l`/`i`→`1`) — WITHOUT [preScrub]'s
  /// inter-digit space squash. The squash is correct for a single cell
  /// (`0 6 0 0` → `0600`) but catastrophic across columns: it would merge
  /// `0600 1800` into `06001800` and hide the second time. [findTimes] must
  /// keep the gap, so it uses this lighter scrub.
  static String _scrubLetters(String s) =>
      s.replaceAll('o', '0').replaceAll('l', '1').replaceAll('i', '1');

  /// Every time on [line], left→right, as minute-of-day ints. Used by
  /// [parseRange] to detect a whitespace-separated start/end pair; exposed for
  /// tests.
  @visibleForTesting
  static List<int> findTimes(String line) {
    final out = <int>[];
    for (final m in _anyTime.allMatches(_scrubLetters(line.toLowerCase()))) {
      if (m.group(1) != null) {
        // 12h arm.
        var hour = int.parse(m.group(1)!);
        final minute = m.group(2) == null ? 0 : int.parse(m.group(2)!);
        if (m.group(3) == 'p') {
          if (hour != 12) hour += 12;
        } else if (hour == 12) {
          hour = 0;
        }
        out.add(hour * 60 + minute);
      } else {
        // 24h arm.
        out.add(int.parse(m.group(4)!) * 60 + int.parse(m.group(5)!));
      }
    }
    return out;
  }

  /// Range branch: split [lower] on a separator and, if exactly two halves
  /// each yield a time, fill start + end. Splitting happens BEFORE the
  /// pre-scrub so the `to` separator isn't mangled by the `o`→`0` mapping;
  /// each half is scrubbed individually. Letter ranges (`D-N`) intentionally
  /// fall through to null.
  static ShiftBlock? _tryRange(String lower) {
    final parts = lower.split(_rangeSep);
    if (parts.length != 2) return null;
    final start = _timeMinutes(preScrub(parts[0].trim()));
    final end = _timeMinutes(preScrub(parts[1].trim()));
    if (start == null || end == null) return null;
    return ShiftBlock(startMinutes: start, endMinutes: end);
  }

  /// Single-time branch: a start time with an unknown end.
  static ShiftBlock? _trySingleTime(String timeStr) {
    final start = _timeMinutes(timeStr);
    return start == null ? null : ShiftBlock(startMinutes: start);
  }

  /// Extracts a single minute-of-day from [timeStr], or null. 12h wins when
  /// an am/pm modifier is present (see class-doc ordering note); pure-numeric
  /// strings go straight to the 24h tier.
  static int? _timeMinutes(String timeStr) => _hasAmPm.hasMatch(timeStr)
      ? (_match12h(timeStr) ?? _match24h(timeStr))
      : (_match24h(timeStr) ?? _match12h(timeStr));

  static int? _match24h(String s) {
    final m = _tier24h.firstMatch(s);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static int? _match12h(String s) {
    final m = _tier12h.firstMatch(s);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!); // 1–12
    final minute = m.group(2) == null ? 0 : int.parse(m.group(2)!);
    final isPm = m.group(3) == 'p';
    if (isPm) {
      if (hour != 12) hour += 12; // 1–11 pm → +12; 12 pm stays noon
    } else {
      if (hour == 12) hour = 0; // 12 am → midnight
    }
    return hour * 60 + minute;
  }

  /// Tier 3: the grid-letter fallback, read off the un-substituted [lower]
  /// string. Matches only when the cell reduces to a single recognised
  /// token, so multi-char tokens like `O6OO` (already handled as a time)
  /// never reach here.
  ///
  /// Digits are kept when reducing the token so a handwritten 'O' that ML Kit
  /// misreads as the digit `0` still resolves: a lone `0` maps to Off, exactly
  /// like the letter `o`. Real numeric times are multi-char and consumed by the
  /// time tiers first, so they never reach this fallback.
  static ShiftBlock? _tier3Letter(String lower) {
    final token = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    // The explicit word "OFF" (already lower-cased) → a rest day, exactly like
    // the single letter 'O'. Retail rosters spell the whole word on rest days;
    // without this it falls through every tier and the rest day is dropped,
    // shifting every later day onto the wrong date.
    if (token == 'off') {
      return const ShiftBlock(
        startMinutes: 0,
        endMinutes: 0,
        type: ShiftType.off,
      );
    }
    if (token.length != 1) return null;
    switch (token) {
      case 'd': // Day — 06:00 → 18:00
        return const ShiftBlock(
          startMinutes: 360,
          endMinutes: 1080,
          type: ShiftType.day,
        );
      case 'n': // Night — 18:00 → 06:00
        return const ShiftBlock(
          startMinutes: 1080,
          endMinutes: 360,
          type: ShiftType.night,
        );
      case 'a': // Afternoon — 14:00 → 22:00
        return const ShiftBlock(
          startMinutes: 840,
          endMinutes: 1320,
          type: ShiftType.afternoon,
        );
      case 'o': // Off — recognised non-working block, not a parse failure
      case '0': // handwritten 'O' that ML Kit read as a zero
        return const ShiftBlock(
          startMinutes: 0,
          endMinutes: 0,
          type: ShiftType.off,
        );
      default:
        return null;
    }
  }
}
