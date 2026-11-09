import 'package:flutter/material.dart';

/// INTERRUPTEUR ESTHÉTIQUE
/// true  : style cartoon tunisien (tapis bleu, bordure zellige, fond village, bannières magenta et jaune).
/// false : style d'origine du jeu React (tapis émeraude, cadre brun, fond bois, bannières jaune-orange et sky-indigo).
/// Réglé sur `false` : rendu aligné sur l'application React d'origine.
/// Pour revenir au style cartoon : remplacez `false` par `true` ci-dessous, puis relancez l'application.
const bool kCartoonStyle = false;

class GameStyle {
  const GameStyle({
    required this.felt,
    required this.frame,
    required this.zellige,
    required this.zelligeAccent,
    required this.outline,
    required this.showZellige,
    required this.villageBackground,
    required this.chkobbaGradient,
    required this.ayaGradient,
  });

  final Color felt;
  final Color frame;
  final Color zellige;
  final Color zelligeAccent;
  final Color outline;
  final bool showZellige;

  /// true : fond village (style cartoon). false : fond bois du jeu React.
  final bool villageBackground;

  /// Dégradés des bannières « Chkobba ! » et « 7AYA ! ».
  final List<Color> chkobbaGradient;
  final List<Color> ayaGradient;

  static const cartoon = GameStyle(
    felt: Color(0xFF1E7FD8),
    frame: Color(0xFFC8643B),
    zellige: Color(0xFF1E5BD8),
    zelligeAccent: Color(0xFFFFFFFF),
    outline: Color(0xFF000000),
    showZellige: true,
    villageBackground: true,
    chkobbaGradient: [Color(0xFFF5C842), Color(0xFFF08A1C)],
    ayaGradient: [Color(0xFFE0218A), Color(0xFF7A1A9E)],
  );

  // Valeurs d'origine (React) : emerald-500, cadre brun, yellow-300 → orange-500, sky-300 → indigo-600.
  static const original = GameStyle(
    felt: Color(0xFF10B981),
    frame: Color(0xFF4A2A10),
    zellige: Color(0xFF4A2A10),
    zelligeAccent: Color(0xFF4A2A10),
    outline: Color(0xFF000000),
    showZellige: false,
    villageBackground: false,
    chkobbaGradient: [Color(0xFFFDE047), Color(0xFFF97316)],
    ayaGradient: [Color(0xFF7DD3FC), Color(0xFF4F46E5)],
  );

  static GameStyle get current => kCartoonStyle ? cartoon : original;
}
