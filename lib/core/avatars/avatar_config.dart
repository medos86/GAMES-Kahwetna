import 'package:flutter/widgets.dart';

/// Réglages d'affichage des avatars (issue #935).
///
/// Un avatar trop grand devient difficile à lire : [maxDisplaySize] plafonne la
/// taille affichée, quelle que soit la taille demandée par l'écran. Modifier ici
/// suffit pour toute l'application.
class AvatarConfig {
  const AvatarConfig._();

  /// Taille maximale d'affichage, en dp. Au-delà, l'avatar est plafonné à cette valeur.
  static const double maxDisplaySize = 88;

  /// Qualité de rendu de l'image (redimensionnement lissé pour rester net).
  static const FilterQuality filterQuality = FilterQuality.high;
}

/// Taille effective d'affichage pour une taille demandée, plafonnée par [AvatarConfig].
double effectiveAvatarSize(double requested) =>
    requested > AvatarConfig.maxDisplaySize
        ? AvatarConfig.maxDisplaySize
        : requested;
