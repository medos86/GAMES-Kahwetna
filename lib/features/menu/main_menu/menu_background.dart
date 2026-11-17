part of '../main_menu_screen.dart';

class _Background extends StatelessWidget {
  const _Background({
    required this.difficulty,
    this.imageAsset = kMenuBackgroundAsset,
  });

  final Difficulty difficulty;
  // Photo du jeu (écran de niveau) ou fond commun du menu.
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final filter = switch (difficulty) {
      Difficulty.facile => _colorAdjust(brightness: 1.05, saturation: 1.10),
      Difficulty.moyen => _colorAdjust(brightness: 0.90, saturation: 1.25),
      Difficulty.difficile => _colorAdjust(brightness: 0.58, saturation: 0.80),
    };
    final scale = switch (difficulty) {
      Difficulty.facile => 1.0,
      Difficulty.moyen => 1.02,
      Difficulty.difficile => 1.04,
    };
    final glowOpacity = switch (difficulty) {
      Difficulty.facile => 0.0,
      Difficulty.moyen => 0.22,
      Difficulty.difficile => 0.36,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond commun au menu, ou photo du jeu sur l'écran de niveau.
        Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: filter,
            child: Image.asset(
              imageAsset,
              key: ValueKey(imageAsset),
              semanticLabel: Strings.menuBackgroundAlt,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, error, __) => ColoredBox(
                color: const Color(0xFF2BB8EA),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    // Diagnostic temporaire : affiche la raison exacte si l'image ne se charge pas.
                    child: Text(
                      'Fond introuvable : $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (kComicMenu)
          const IgnorePointer(child: HalftoneOverlay(child: SizedBox.expand())),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: _tint(difficulty)),
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: glowOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _glow(difficulty)),
            ),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.64),
                radius: 0.9,
                colors: [Colors.transparent, Color(0x33051836)],
                stops: [0.28, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static LinearGradient _tint(Difficulty d) {
    const top = [Color(0x40063A6B), Color(0x00000000), Color(0xBF101638)];
    const moyen = [Color(0x40A52D1D), Color(0x1AFF8A3D), Color(0xCC311631)];
    const difficile = [Color(0xA6080D37), Color(0x40351455), Color(0xF2080B24)];
    final colors = switch (d) {
      Difficulty.facile => top,
      Difficulty.moyen => moyen,
      Difficulty.difficile => difficile,
    };
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
  }

  static Gradient _glow(Difficulty d) {
    if (d == Difficulty.difficile) {
      return const RadialGradient(
        center: Alignment(0.56, -0.76),
        radius: 0.45,
        colors: [Color(0xFFAE9CFF), Colors.transparent],
      );
    }
    return const RadialGradient(
      center: Alignment(0.44, -0.6),
      radius: 0.5,
      colors: [Color(0xFFFFDF67), Colors.transparent],
    );
  }

  /// Luminosité et saturation approximées par une matrice de couleur (les sépia et rotation de teinte sont omis).
  static ColorFilter _colorAdjust({
    required double brightness,
    required double saturation,
  }) {
    final s = saturation;
    final b = brightness;
    return ColorFilter.matrix([
      (0.213 + 0.787 * s) * b,
      (0.715 - 0.715 * s) * b,
      (0.072 - 0.072 * s) * b,
      0,
      0,
      (0.213 - 0.213 * s) * b,
      (0.715 + 0.285 * s) * b,
      (0.072 - 0.072 * s) * b,
      0,
      0,
      (0.213 - 0.213 * s) * b,
      (0.715 - 0.715 * s) * b,
      (0.072 + 0.928 * s) * b,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
