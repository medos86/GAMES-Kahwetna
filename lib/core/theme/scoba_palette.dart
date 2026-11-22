import 'package:material_ui/material_ui.dart';

import 'comic_palette.dart';

/// Palette Scoba en style BD (issue #289) : fond papier, couleurs vives, encre noire.
/// Textes et fonds sont choisis pour respecter un contraste WCAG d'au moins 4,5 (voir test).
abstract final class ScobaPalette {
  /// Tapis de jeu clair et vif (remplace le vert émeraude sombre).
  static const Color felt = Color(0xFF56CCF2);
  static const Color feltDeep = Color(0xFF2F9BD6);

  /// Fond bleu BD de la Chkobba (#752) : bleu vif de dessin animé, plus clair que le bleu tunisien.
  static const Color tapisBleu = Color(0xFF1E9BFF);

  /// Feutre vert BD du tapis de Chkobba (#752) : vert vif de dessin animé, contour encre.
  static const Color tapisVert = Color(0xFF2FBF5B);

  /// Fond des panneaux (cartes de manche, choix de prise).
  static const Color panel = ComicPalette.paper;
  static const Color ink = ComicPalette.ink;

  /// Piles et accents.
  static const Color red = ComicPalette.red;
  static const Color blue = ComicPalette.tunisBlue;
  static const Color yellow = ComicPalette.yellow;

  /// Couleurs de texte lisibles sur papier ou fond blanc.
  static const Color redText = Color(0xFFB0202C);
  static const Color blueText = Color(0xFF0B5CAD);
}
