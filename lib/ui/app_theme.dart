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
///
/// The app now ships BOTH a dark theme (the default, and the identity) and an
/// optional warm "cream" light theme, selected via a persisted preference. Both
/// are built from the SAME [_rostrikThemeFromScheme] helper so the button /
/// card / switch / app-bar styling can never drift between them — only the
/// [ColorScheme] differs.

/// High-visibility safety-orange accent. Bright enough to read at a glance at
/// 4am on a locked screen, which is the whole point. Lightened one shade from
/// the original `#FF6D00` so it reads vivid (not muddy) against true OLED black.
const Color kRostrikOrange = Color(0xFFFF8F00);

/// The light theme's accent — a deeper "burnt amber". The bright [kRostrikOrange]
/// is gorgeous on black but too pale to read as text/icon/border tint on the
/// cream background (it fails WCAG contrast), so the light scheme steps the
/// primary down to this richer shade. Still unmistakably the same brand orange,
/// just legible on cream (black label on this fill ≈ 5.6:1, the tint on cream
/// ≈ 3.4:1 — passes for large text / UI components).
const Color kRostrikOrangeDeep = Color(0xFFCC6A00);

/// Near-black scaffold background — not pure `#000000`, a hair of warmth so OLED
/// blacks don't look like dead pixels against the orange.
const Color kRostrikBlack = Color(0xFF0A0A0B);

/// Deep-grey raised surface (cards, sheets, app bars).
const Color kRostrikSurface = Color(0xFF161618);

/// Slightly lighter grey for nested containers / selected fills.
const Color kRostrikSurfaceHigh = Color(0xFF202024);

/// The light theme's page background — a warm paper "cream" (the requested
/// `#FAF3DD`). Cards/sheets sit a shade lighter than this so they lift off it.
const Color kRostrikCream = Color(0xFFFAF3DD);

/// The forced dark theme's [ColorScheme]. Built from an orange-seeded Material 3
/// scheme, then overridden so the surfaces stay pitch-black/deep-grey and the
/// primary is the full-strength accent rather than M3's muted tonal derivation.
ColorScheme _rostrikDarkScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kRostrikOrange,
    brightness: Brightness.dark,
  );

  return base.copyWith(
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
}

/// The optional light theme's [ColorScheme] — warm cream paper with a deeper
/// burnt-amber accent so text/icons stay legible on the pale background. Cards
/// step lighter than the cream page; nested/selected fills step slightly darker
/// so the surface hierarchy still reads without shadows.
ColorScheme _rostrikLightScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kRostrikOrange,
    brightness: Brightness.light,
  );

  return base.copyWith(
    primary: kRostrikOrangeDeep,
    onPrimary: Colors.black,
    secondary: kRostrikOrangeDeep,
    onSecondary: Colors.black,
    surface: kRostrikCream,
    onSurface: const Color(0xFF2B2A24),
    // Cards/sheets sit LIGHTER than the cream page so they lift off it; the
    // "high" containers step warmer/darker for nested + selected fills.
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFFFFDF6),
    surfaceContainer: const Color(0xFFFFFBF0),
    surfaceContainerHigh: const Color(0xFFF3EBCF),
    surfaceContainerHighest: const Color(0xFFECE3C4),
    onSurfaceVariant: const Color(0xFF6E685A),
    outline: const Color(0xFFC7BE9E),
    outlineVariant: const Color(0xFFE2D9BC),
  );
}

/// The dark theme (the app's default + identity).
ThemeData rostrikDarkTheme() => _rostrikThemeFromScheme(_rostrikDarkScheme());

/// The optional warm-cream light theme, selected via the Appearance preference.
ThemeData rostrikLightTheme() => _rostrikThemeFromScheme(_rostrikLightScheme());

/// Builds the shared Rostrik [ThemeData] from a [ColorScheme]. Every non-colour
/// decision (flat app bars, 16px cards, orange-track switches, orange progress,
/// orange filled CTAs) lives here so the dark and light themes can only ever
/// differ by their scheme — never by their component styling.
ThemeData _rostrikThemeFromScheme(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    // Flat, industrial app bars that sit on the background rather than floating.
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
