import 'package:flutter/material.dart';

/// Rostrik's visual identity: a dark, minimal, premium "industrial tool" look —
/// pitch-black / deep-grey surfaces with a bold, high-visibility orange accent
/// reserved for active selection states, progress, and primary actions.
///
/// Centralised here (rather than inline in `main.dart`) so every accent the app
/// draws — the onboarding selection borders, the Dashboard cards, the
/// FilledButtons, the wake-up controls — reads from one source of truth. Most
/// screens already accent off `colorScheme.primary` / `Card` / `FilledButton`,
/// so swapping the seed restyles them for free.

/// High-visibility safety-orange accent. Bright enough to read at a glance at
/// 4am on a locked screen, which is the whole point. Lightened one shade from
/// the original `#FF6D00` so it reads vivid (not muddy) against true OLED black.
const Color kRostrikOrange = Color(0xFFFF8F00);

/// Near-black scaffold background — not pure `#000000`, a hair of warmth so OLED
/// blacks don't look like dead pixels against the orange.
const Color kRostrikBlack = Color(0xFF0A0A0B);

/// Deep-grey raised surface (cards, sheets, app bars).
const Color kRostrikSurface = Color(0xFF161618);

/// Slightly lighter grey for nested containers / selected fills.
const Color kRostrikSurfaceHigh = Color(0xFF202024);

/// The forced dark theme (the app pins `ThemeMode.dark`). Built from an
/// orange-seeded Material 3 scheme, then overridden so the surfaces stay
/// pitch-black/deep-grey and the primary is the full-strength accent rather
/// than M3's muted tonal derivation.
ThemeData rostrikDarkTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kRostrikOrange,
    brightness: Brightness.dark,
  );

  final scheme = base.copyWith(
    primary: kRostrikOrange,
    onPrimary: Colors.black,
    secondary: kRostrikOrange,
    onSecondary: Colors.black,
    surface: kRostrikBlack,
    onSurface: const Color(0xFFF2F2F3),
    surfaceContainerLowest: kRostrikBlack,
    surfaceContainerLow: const Color(0xFF101012),
    surfaceContainer: kRostrikSurface,
    surfaceContainerHigh: kRostrikSurfaceHigh,
    surfaceContainerHighest: const Color(0xFF2A2A2E),
    onSurfaceVariant: const Color(0xFF9A9AA0),
    outline: const Color(0xFF3A3A40),
    outlineVariant: const Color(0xFF2A2A30),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    // Flat, industrial app bars that sit on the black rather than floating.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // Primary actions are the bold orange — high-visibility CTAs.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHigh,
        disabledForegroundColor: scheme.onSurfaceVariant,
      ),
    ),
    // Active selection states (chips, segmented buttons) pick up the accent
    // through the scheme; the switch track gets the explicit orange so the
    // permission/alarm toggles read as "armed".
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
    ),
  );
}
