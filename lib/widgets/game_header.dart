import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';
import '../core/theme/comic_palette.dart';
import 'comic/comic_panel.dart';
import 'pressable.dart';

/// En-tête commun des écrans de jeu (#242).
///
/// Pastille Menu à gauche (style BD), contenu central et emplacement à droite.
/// [center] et [trailing] sont placés tels quels dans la ligne : [center] doit donc
/// être un `Expanded` ou un `Flexible`. La position ne dépend ni du jeu ni de la langue.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.onMenu,
    this.unit = 16,
    this.center,
    this.trailing,
  });

  final VoidCallback onMenu;

  /// Taille de référence du header, en dp (les autres tailles en sont proportionnelles).
  final double unit;

  /// Contenu central (ex. manche et difficulté). Un `Spacer` si absent.
  final Widget? center;

  /// Contenu à droite (ex. trophée et score cible).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          semanticLabel: Strings.menuLabel,
          onTap: onMenu,
          child: _MenuPill(unit: unit),
        ),
        center ?? const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Bouton Menu en case BD : contour encre, libellé en Bangers.
class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: ComicPalette.paper,
      outlineColor: ComicPalette.ink,
      radius: 12,
      shadowOffset: const Offset(3, 3),
      padding: EdgeInsets.symmetric(horizontal: unit, vertical: unit * 0.55),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: unit, color: ComicPalette.ink),
          SizedBox(width: unit * 0.4),
          Text(
            Strings.menuLabel,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: unit * 0.95,
              letterSpacing: 1,
              color: ComicPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
