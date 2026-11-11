import 'package:flutter/material.dart';

/// INTERRUPTEUR ESTHÉTIQUE
/// true  : style cartoon tunisien (tapis bleu, bordure zellige, fond village, bannières magenta et jaune).
/// false : style d'origine du jeu React (tapis émeraude, cadre brun, fond bois, bannières jaune-orange et sky-indigo).
/// Réglé sur `true` : palette A (violet-magenta, issue #64). Pour revenir au style React : `false`.
const bool kCartoonStyle = true;

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

  // Palette A (issue #64) : tapis violet-magenta, cadre noir, bannières jaune-orange et rose-jaune.
  static const cartoon = GameStyle(
    felt: Color(0xFF5B2BD6),
    frame: Color(0xFF000000),
    zellige: Color(0xFF8E1AB8),
    zelligeAccent: Color(0xFFFFFFFF),
    outline: Color(0xFF000000),
    showZellige: true,
    villageBackground: true,
    chkobbaGradient: [Color(0xFFFFE14D), Color(0xFFFF8A2B)],
    ayaGradient: [Color(0xFFFF4F9A), Color(0xFFFFE14D)],
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
