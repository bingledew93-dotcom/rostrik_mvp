import '../data/models/shift_type.dart';

/// One shift extracted from an LLM's reply by [RosterAiParser].
///
/// Deliberately close to the wire format: [shiftType] / [startTime] / [endTime]
/// are the raw strings the model emitted ("Day", "06:00"), with [date] already
/// resolved to a `DateTime` at local midnight. The typed conveniences ([type],
/// [startMinutes], [endMinutes]) map those onto the app's domain so the import
/// path can build [Shift]s without re-parsing. Immutable + value-equal so the
/// preview list and the parser tests compare cleanly.
class ParsedShift {
  const ParsedShift({
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
  });

  /// Local-midnight calendar day this shift falls on.
  final DateTime date;

  /// Raw day type as matched: exactly "Day", "Afternoon", "Night", or "Off".
  final String shiftType;

  /// Raw start clock, "HH:MM" (24-hour). "00:00" for an Off day.
  final String startTime;

  /// Raw end clock, "HH:MM" (24-hour). "00:00" for an Off day.
  final String endTime;

  /// The domain [ShiftType]. The parser only ever stores one of the four
  /// allowed strings, so the fallback is unreachable (kept to stay total).
  ShiftType get type {
    switch (shiftType) {
      case 'Afternoon':
        return ShiftType.afternoon;
      case 'Night':
        return ShiftType.night;
      case 'Off':
        return ShiftType.off;
      case 'Day':
      default:
        return ShiftType.day;
    }
  }

  /// Returns a copy reclassified to [newType], preserving the clock strings —
  /// backs the preview's tap-to-change-type affordance. Callers restrict this
  /// to the three WORKING types (Day/Afternoon/Night): reclassifying to Off
  /// would strand a working shift's clock (an Off day is 00:00–00:00), and a
  /// working shift with a non-zero clock is exactly what the user wants kept
  /// when they only meant to fix the label.
  ParsedShift withType(ShiftType newType) => ParsedShift(
        date: date,
        shiftType: canonicalTypeLabel(newType),
        startTime: startTime,
        endTime: endTime,
      );

  /// The exact string the parser/prompt use for each [ShiftType] — the single
  /// source of truth for the type↔string mapping, so [withType] can round-trip
  /// through [type] without drift.
  static String canonicalTypeLabel(ShiftType t) {
    switch (t) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        return 'Off';
    }
  }

  /// Start minute-of-day (0..1439). Off days are canonicalised to 0 regardless
  /// of the clock the model emitted — an Off shift has no working time range.
  int get startMinutes => type == ShiftType.off ? 0 : _hhmmToMinutes(startTime);

  /// End minute-of-day (0..1439); 0 for Off days (see [startMinutes]).
  int get endMinutes => type == ShiftType.off ? 0 : _hhmmToMinutes(endTime);

  static int _hhmmToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedShift &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          shiftType == other.shiftType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(date, shiftType, startTime, endTime);

  @override
  String toString() =>
      'ParsedShift(${date.toIso8601String()}, $shiftType, '
      '$startTime - $endTime)';
}

/// Parses the strict line format the AI is prompted to emit
/// (see `kRosterAiPromptTemplate`) into a list of [ParsedShift]s.
///
/// Tolerant by design: it scans line-by-line and keeps only the lines that
/// match the contract exactly, so a stray greeting, a trailing "Let me know if
/// you need changes!", blank lines, or `\r\n` endings from a copy-paste are all
/// silently ignored rather than failing the whole import. A structurally-valid
/// line whose values are out of range (e.g. `31/02/2026`, `25:00`) is also
/// dropped — never coerced into a wrong date/time.
class RosterAiParser {
  RosterAiParser._();

  /// The line contract. Matches, per the prompt:
  ///   `DD/MM/YYYY | Day|Afternoon|Night|Off | HH:MM - HH:MM`
  /// with flexible whitespace around the pipes and the dash. Anchored so a line
  /// with leading markdown/bullet text won't match (the prompt forbids it).
  static final RegExp _linePattern = RegExp(
    r'^(\d{2}\/\d{2}\/\d{4})\s*\|\s*(Day|Afternoon|Night|Off)\s*\|\s*(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$',
  );

  /// Extracts every valid shift line from [rawText], in the order they appear.
  /// Returns an empty list when nothing matches (the UI treats that as "no
  /// valid shifts detected").
  static List<ParsedShift> parseAiOutput(String rawText) {
    final out = <ParsedShift>[];
    for (final rawLine in rawText.split('\n')) {
      final line = rawLine.trim(); // also strips a trailing '\r' on Windows.
      if (line.isEmpty) continue;
      final match = _linePattern.firstMatch(line);
      if (match == null) continue;

      final date = _parseDate(match.group(1)!);
      if (date == null) continue; // impossible calendar date → skip the line.
      if (!_validHhmm(match.group(3)!) || !_validHhmm(match.group(4)!)) {
        continue; // out-of-range clock (e.g. 25:00 / 12:70) → skip.
      }

      out.add(ParsedShift(
        date: date,
        shiftType: match.group(2)!,
        startTime: match.group(3)!,
        endTime: match.group(4)!,
      ));
    }
    return out;
  }

  /// "DD/MM/YYYY" (day-first) → local-midnight [DateTime], or null if the parts
  /// don't form a real calendar date. Guards against Dart's silent rollover
  /// (`DateTime(2026, 2, 31)` → early March) by verifying the fields survive the
  /// round-trip.
  static DateTime? _parseDate(String ddmmyyyy) {
    final parts = ddmmyyyy.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// The RegExp guarantees `\d{2}:\d{2}`; this only range-checks the fields.
  static bool _validHhmm(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }
}
