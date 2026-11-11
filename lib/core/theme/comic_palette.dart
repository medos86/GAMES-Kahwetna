import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  /// Trame de points (alpha 15 %).
  static const Color halftone = Color(0x26000000);
}

/// Rapport de contraste WCAG entre deux couleurs (1 à 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}
