import 'dart:math' as math;

/// Reproduit les formules CSS du projet React (dimensionnement des jeux).
///
/// Source : `--game-unit`, `--hand-card-width` (RamiGameScreen), `--card-width`
/// (CoincheGameScreen), et le point de bascule `(orientation: portrait) and (max-width: 600px)`
/// utilisé dans tous les écrans de jeu.
///
/// Pur Dart : aucun import Flutter, donc testable sans émulateur.
class DeviceMetrics {
  const DeviceMetrics({required this.width, required this.height});

  /// Largeur et hauteur de la zone disponible, en dp (= px CSS des outils de développement).
  final double width;
  final double height;

  /// Taille de base CSS (`html { font-size: 16px }` dans theme.css).
  static const double rem = 16;

  /// Équivalent de `(orientation: portrait)`.
  bool get isPortrait => height > width;

  /// Équivalent de `(orientation: portrait) and (max-width: 600px)`.
  /// Mode compact : colonnes au lieu de rangées, en-têtes resserrés.
  bool get isCompact => isPortrait && width <= 600;

  /// `--game-unit`.
  /// Compact : `clamp(0.875rem, 3.5vw, 1.125rem)`.
  /// Sinon   : `clamp(0.75rem, 2vmin, 1rem)`.
  double get gameUnit => isCompact
      ? _clamp(0.875 * rem, 0.035 * width, 1.125 * rem)
      : _clamp(0.75 * rem, 0.02 * math.min(width, height), 1.0 * rem);

  /// `--hand-card-width` du Rami : `min(3.4rem, 13.5vw)`.
  double get ramiHandCardWidth => math.min(3.4 * rem, 0.135 * width);

  /// `--card-width` de la Coinche : `min(4.5rem, calc((100vw - 3.75rem) / 5.6))`.
  double get coincheCardWidth =>
      math.min(4.5 * rem, (width - 3.75 * rem) / 5.6);

  static double _clamp(double low, double value, double high) =>
      math.max(low, math.min(value, high));
}
