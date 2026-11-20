import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Palette du thème BD (issue #93). Toute couleur du thème BD passe par ici.
///
/// Règle des 5 % : le bleu tunisien n'apparaît que sur un liseré ou un motif
/// (barre de titre, en-têtes de panneau), jamais sur les zones de jeu.
abstract final class ComicPalette {
  static const Color ink = Color(0xFF15111A);
  static const Color paper = Color(0xFFFFF8E7);
  static const Color red = Color(0xFFE63946);
  static const Color yellow = Color(0xFFFFD60A);
  static const Color tunisBlue = Color(0xFF1676D2);
  static const Color gold = Color(0xFFFFE16B);
  static const Color goldInk = Color(0xFF3D351F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color seatGreen = Color(0xFF2E9E5B);

  /// Tapis de jeu (Rami, Coinche, Chkobba) : vert BD (#634), contour encre.
  static const Color felt = seatGreen;

  /// Bois du décor de table, commun à tous les jeux de cartes (#633).
  static const Color tableWood = Color(0xFF8B4513);

  /// Trame de points (alpha 15 %).
  static const Color halftone = Color(0x26000000);

  /// Trame du fond de page (alpha 8 %), plus discrète que [halftone].
  static const Color backdropDots = Color(0x14000000);
}

/// Couleurs des toasts (issue #64 : sortie des couleurs en dur hors du thème).
abstract final class ToastPalette {
  static const Color background = Color(0xF2101A33);
  static const Color text = Color(0xFFFFFFFF);
  static const Color subtleText = Color(0xB3FFFFFF);
  static const Color info = Color(0xFF60A5FA);
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFF87171);
}

/// Rapport de contraste WCAG entre deux couleurs (1 à 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}
