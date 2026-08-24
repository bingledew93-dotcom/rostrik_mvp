import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/shift_type.dart';
import 'ocr_text_sanitizer.dart';
import 'ocr_time_parser.dart';
import 'shift_block.dart';

/// The longest-edge pixel cap applied to every image entering the OCR
/// pipeline — the app's single most important memory-safety lever.
///
/// ML Kit text recognition runs natively and off the UI thread, so the scanner
/// can't *jank*; the real risk on low-to-mid devices is being *killed*. A 50 MP
/// Samsung A15 capture decodes to ~200 MB as an ARGB_8888 bitmap; stacked with
/// the cropped copy and ML Kit's own buffer that overruns the per-app heap on a
/// 4 GB device and trips the low-memory killer (iOS jetsam behaves the same on
/// a 3 GB iPhone SE).
///
/// 2400 is the budget: ML Kit reads reliably from ≈1024 px across the text
/// region, so 2400 keeps headroom for a roster's many small cells while cutting
/// the worst-case A15 bitmap from ~200 MB to ~17 MB (2400×1800×4 B) — a >10×
/// reduction applied by the picker BEFORE any Dart code touches the pixels. The
/// subsequent crop only shrinks it further. Do not raise this without
/// re-checking that budget.
const int kMaxScanEdgePx = 2400;

/// JPEG re-encode quality (0–100) for the picked image. Bounds the on-disk temp
/// size; the decoded-bitmap RSS is governed by [kMaxScanEdgePx]. 85 is visually
/// lossless for printed text, so OCR accuracy is unaffected.
const int kScanJpegQuality = 85;

/// The product of a review-flow scan: the parsed [ShiftBlock]s plus, when the
/// caller asked for it, the cropped source image so the review UI can show it
/// next to the parsed list.
@immutable
class ScanResult {
  const ScanResult({required this.blocks, this.croppedImage});

  /// Parsed roster cells, in reading order. Empty means "nothing to inject"
  /// (user backed out, or no times recognised) — never an error.
  final List<ShiftBlock> blocks;

  /// Cropped scan as a compressed JPEG, or null when not captured. Decode at
  /// display size (`Image.memory(..., cacheWidth: ...)`), never full-res.
  final Uint8List? croppedImage;

  /// The "nothing to inject" sentinel — an empty result with no image.
  static const ScanResult empty = ScanResult(blocks: <ShiftBlock>[]);
}

/// The on-device hardware pipeline for the Phase-6 roster scanner:
///
///   camera OR gallery ([image_picker]) → tight crop ([image_cropper]) →
///   text recognition ([google_mlkit_text_recognition]) → [OcrTimeParser]
///
/// **Strict on-device.** `google_mlkit_text_recognition` runs a bundled Latin
/// recognition model entirely on the device — there is no cloud option in the
/// API and no network call is made. Nothing here uploads the image or text.
///
/// Dependencies are injectable so the (testable) text-splitting step can be
/// exercised without hardware; the camera/crop/recognise round-trip itself is
/// only meaningful on a real device.
class OcrScannerService {
  OcrScannerService({
    ImagePicker? picker,
    ImageCropper? cropper,
    TextRecognizer? recognizer,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper(),
        _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _picker;
  final ImageCropper _cropper;
  final TextRecognizer _recognizer;

  /// Defensive single-flight latch (see [_scan]): true while a scan is mid-
  /// flight so a second overlapping run — which would stack peak memory — is
  /// refused. The custom-builder UI also disables its buttons, but the
  /// invariant lives here so it holds for every caller.
  bool _scanInProgress = false;

  /// Captures a roster photo with the **camera** and runs the full pipeline,
  /// returning just the parsed blocks. Delegates to [_scan]; see there for the
  /// shared crop → recognise → parse steps and the "empty means nothing to
  /// inject" contract.
  Future<List<ShiftBlock>> scanRoster() async =>
      (await _scan(ImageSource.camera, keepImage: false)).blocks;

  /// Picks an existing image from the **photo gallery** (a portal screenshot
  /// or a PDF export) and runs the IDENTICAL pipeline as [scanRoster] — only
  /// the image source differs. Digital rosters crop and recognise far more
  /// cleanly than a camera photo, so this is the high-accuracy path.
  Future<List<ShiftBlock>> scanFromGallery() async =>
      (await _scan(ImageSource.gallery, keepImage: false)).blocks;

  /// Camera variant for the Human-in-the-Loop review flow: identical pipeline,
  /// but the [ScanResult] also carries the cropped image bytes so the review
  /// screen can show the source next to the parsed list. See [_scan] for why
  /// the bytes are read into memory rather than handed out as a temp path.
  Future<ScanResult> scanRosterForReview() =>
      _scan(ImageSource.camera, keepImage: true);

  /// Gallery variant for the review flow. See [scanRosterForReview].
  Future<ScanResult> scanFromGalleryForReview() =>
      _scan(ImageSource.gallery, keepImage: true);

  /// The single capture pipeline shared by camera and gallery: pick an image
  /// from [source] → tight crop → on-device ML Kit → [OcrTimeParser]. Only the
  /// `pickImage` source varies between the two entry points; the crop, the
  /// recognition, and the parsing are byte-for-byte identical.
  ///
  /// Returns [ScanResult.empty] (NOT null) when the user backs out of the
  /// picker or the crop, or when the image yielded no parseable times — callers
  /// treat "empty" as "nothing to inject", never as an error.
  ///
  /// When [keepImage] is set, the cropped JPEG is read into memory BEFORE the
  /// `finally` deletes the temp, so the review screen can show the source
  /// without us leaking the cache file. The bytes are the compressed JPEG
  /// (small); decode them at display size, never full-res.
  Future<ScanResult> _scan(
    ImageSource source, {
    required bool keepImage,
  }) async {
    // Defensive single-flight: ML Kit recognition plus a freshly decoded
    // bitmap are the heaviest things this app does for memory, so two
    // overlapping scans would stack their peak RSS and risk an OOM kill on a
    // 4 GB device. Re-entry is treated as "nothing to inject", consistent with
    // the back-out/empty contract in the doc above.
    if (_scanInProgress) return ScanResult.empty;
    _scanInProgress = true;

    // Both temps live in the app cache dir (the picker copies/re-encodes the
    // asset, the cropper writes a new file) — never the user's photo library —
    // so we own them and delete them in the finally regardless of outcome.
    String? pickedPath;
    String? croppedPath;
    try {
      final photo = await _picker.pickImage(
        source: source,
        // The single most important memory-safety lever — see [kMaxScanEdgePx].
        // Capping both dimensions caps the long edge (aspect ratio preserved),
        // so a 50 MP capture can't balloon to ~200 MB and trip the low-memory
        // killer on an A15 / iPhone SE. The re-encode also normalises EXIF
        // orientation into the pixels.
        maxWidth: kMaxScanEdgePx.toDouble(),
        maxHeight: kMaxScanEdgePx.toDouble(),
        imageQuality: kScanJpegQuality,
        // We only need the pixels. Skipping full metadata avoids the iOS
        // photo-library permission prompt — a camera capture doesn't need it,
        // and gallery picking goes through PHPicker which doesn't either.
        requestFullMetadata: false,
      );
      if (photo == null) return ScanResult.empty;
      pickedPath = photo.path;

      final cropped = await _cropper.cropImage(
        sourcePath: photo.path,
        // Hard cap on the CROP OUTPUT bitmap (Play Console: "Improve your
        // app's performance with bitmap downsampling"). The picked image is
        // already capped above, but image_picker's resize is documented as
        // best-effort and some OEM camera paths hand back the full-res frame
        // regardless — in which case uCrop would decode it, and then ML Kit
        // would decode the oversized crop AGAIN. Capping here makes the bound
        // on every bitmap that reaches the recognizer unconditional rather
        // than dependent on the picker honouring its own request.
        maxWidth: kMaxScanEdgePx,
        maxHeight: kMaxScanEdgePx,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop to YOUR row only — not the whole team',
            lockAspectRatio: false,
            hideBottomControls: false,
            // Free-form crop, seeded at the original ratio so the user starts
            // from the whole frame and drags inward onto just the grid.
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: 'Crop to YOUR row only — not the whole team',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      if (cropped == null) return ScanResult.empty;
      croppedPath = cropped.path;

      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(cropped.path));
      final blocks = parseRecognizedText(recognized);
      // Read the cropped bytes while the temp still exists — the finally below
      // deletes it — but only when the caller actually wants the reference
      // image, so the inject-only paths skip the extra IO.
      final image =
          keepImage ? await File(cropped.path).readAsBytes() : null;
      return ScanResult(blocks: blocks, croppedImage: image);
    } finally {
      _scanInProgress = false;
      // Best-effort: drop the cache temps so repeated scans don't accumulate
      // downscaled-but-still-sizeable images in the cache dir.
      await _deleteTemp(pickedPath);
      await _deleteTemp(croppedPath);
    }
  }

  /// Best-effort delete of a pipeline cache temp (`null` paths are ignored).
  /// Both the picked copy and the crop output live in the app cache dir, never
  /// the user's library, so this only reclaims our own scratch files. Any
  /// failure is swallowed: a stray cache file is harmless and the OS reclaims
  /// it anyway, and cleanup must never mask the scan result or a real error.
  static Future<void> _deleteTemp(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Intentionally ignored — see doc.
    }
  }

  /// Pure text → blocks step, split out so it is unit-testable without
  /// hardware (ML Kit joins recognised lines with `\n` in [RecognizedText.text],
  /// so the newline split mirrors the on-image layout). The raw text is run
  /// through [OcrTextSanitizer] first to fold unicode noise and rejoin split
  /// ranges, then handed to [parseTextLines].
  @visibleForTesting
  static List<ShiftBlock> parseRecognizedText(RecognizedText recognized) =>
      parseTextLines(OcrTextSanitizer.sanitize(recognized.text));

  /// Splits [rawText] into lines and parses each into shift block(s),
  /// inserting Off blocks for any days skipped between weekday-prefixed lines.
  ///
  /// Per line:
  ///   * A leading weekday token (`mon`..`sun`, or full names) is detected and
  ///     stripped before parsing. When two weekday-prefixed lines appear in
  ///     sequence, the forward day gap between them (mod 7, so `fri`→`mon` is
  ///     3 ⇒ 2 days off) is filled with `Off` blocks — handwritten rosters
  ///     routinely skip the days the user isn't rostered.
  ///   * The remaining text is parsed whole first ([OcrTimeParser] handles
  ///     ranges like `06:00 - 18:00` and spaced am/pm); only if that yields
  ///     nothing is the line whitespace-tokenised — that recovers a grid ROW
  ///     such as `D N O D` (or `D 0 N`, a handwritten Off) where each column
  ///     is its own cell.
  ///
  /// Lines without a weekday don't participate in gap inference; lines that
  /// yield no shift at all (blank lines, a header row like `Mon Tue Wed`) are
  /// dropped without anchoring a gap.
  @visibleForTesting
  static List<ShiftBlock> parseTextLines(String rawText) {
    final out = <ShiftBlock>[];
    int? prevWeekday; // 0=Mon .. 6=Sun, from the last day-anchored line.
    for (final rawLine in rawText.split(RegExp(r'[\r\n]+'))) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final weekday = _leadingWeekday(trimmed);
      final body = weekday == null ? trimmed : _stripLeadingWeekday(trimmed);
      final lineBlocks = _parseLineShifts(body);
      if (lineBlocks.isEmpty) continue; // header-only / unparseable line

      if (weekday != null) {
        if (prevWeekday != null) {
          // Days strictly between prev → current (forward, mod 7) are Off.
          final gap = (weekday - prevWeekday + 7) % 7;
          for (var i = 1; i < gap; i++) {
            out.add(_offBlock);
          }
        }
        prevWeekday = weekday;
      }
      out.addAll(lineBlocks);
    }
    return out;
  }

  /// Parses one line's text into zero or more shift blocks, in priority order:
  ///   1. **Range** ([OcrTimeParser.parseRange]) — an explicit-separator range
  ///      (`9am-5pm`, `9am to 5pm`) OR two time tokens with only whitespace
  ///      between them (`9:15am  5:30pm`, the column layout). Tried FIRST so a
  ///      two-time line becomes one start→end block instead of grabbing the
  ///      start and dropping the end.
  ///   2. **Single value** ([OcrTimeParser.parse]) — one time, or a grid letter.
  ///   3. **Grid row** — whitespace-tokenise into per-cell values (`D N O D`).
  static List<ShiftBlock> _parseLineShifts(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const <ShiftBlock>[];

    final range = OcrTimeParser.parseRange(trimmed);
    if (range != null) return <ShiftBlock>[range];

    final whole = OcrTimeParser.parse(trimmed);
    if (whole != null) return <ShiftBlock>[whole];

    final out = <ShiftBlock>[];
    for (final token in trimmed.split(RegExp(r'\s+'))) {
      final parsed = OcrTimeParser.parse(token);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  /// The weekday at the START of [line] (0=Mon..6=Sun), or null if its leading
  /// word isn't a recognised weekday. The full leading alphabetic run is
  /// matched EXACTLY against [_weekdays], so `march` / a lone `d` aren't
  /// mistaken for a weekday.
  static int? _leadingWeekday(String line) {
    final m = RegExp(r'^[a-z]+').firstMatch(line.toLowerCase());
    if (m == null) return null;
    return _weekdays[m.group(0)!];
  }

  /// Strips the leading weekday word (and any trailing separators) so the
  /// remainder is just the shift text. Only called when [_leadingWeekday]
  /// matched, so the leading alphabetic run IS the weekday token.
  static String _stripLeadingWeekday(String line) =>
      line.replaceFirst(RegExp(r'^[a-z]+', caseSensitive: false), '').trim();

  /// A skipped (non-working) day injected between weekday-prefixed lines.
  static const ShiftBlock _offBlock =
      ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off);

  /// Accepted leading weekday tokens → weekday index (Mon=0 .. Sun=6).
  static const Map<String, int> _weekdays = {
    'mon': 0, 'monday': 0,
    'tue': 1, 'tues': 1, 'tuesday': 1,
    'wed': 2, 'weds': 2, 'wednesday': 2,
    'thu': 3, 'thur': 3, 'thurs': 3, 'thursday': 3,
    'fri': 4, 'friday': 4,
    'sat': 5, 'saturday': 5,
    'sun': 6, 'sunday': 6,
  };

  /// Releases the recognizer's native resources. Call when the owning widget
  /// is disposed.
  Future<void> dispose() => _recognizer.close();
}
