import 'package:material_ui/material_ui.dart';

import 'comic_palette.dart';

/// Thème BD (issue #93) : fond papier, encre noire, boutons jaunes à contour.
/// Activé par `kComicStyle` (lib/core/theme/game_style.dart).
ThemeData buildComicTheme() {
  const scheme = ColorScheme.light(
    primary: ComicPalette.yellow,
    onPrimary: ComicPalette.ink,
    secondary: ComicPalette.tunisBlue,
    onSecondary: ComicPalette.paper,
    error: ComicPalette.red,
    onError: ComicPalette.paper,
    surface: ComicPalette.paper,
    onSurface: ComicPalette.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ComicPalette.paper,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ComicPalette.yellow,
        foregroundColor: ComicPalette.ink,
        elevation: 0,
        side: const BorderSide(color: ComicPalette.ink, width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
