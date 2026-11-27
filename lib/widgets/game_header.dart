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
        // Rétrécit au lieu de déborder quand la largeur manque (arabe, petit écran).
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Pressable(
              semanticLabel: Strings.menuLabel,
              onTap: onMenu,
              pressedScale: 0.92,
              child: _MenuPill(unit: unit),
            ),
          ),
        ),
        center ?? const Spacer(),
        if (trailing != null)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
          ),
      ],
    );
  }
}

/// Bouton retour des jeux : même style que le bouton retour du menu (menu_header.dart),
/// dimensionné sur [unit] pour rester dans l'en-tête.
class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: ComicPalette.ink.withAlpha(0xE6),
      outlineColor: ComicPalette.tunisBlue,
      radius: 14,
      shadowOffset: const Offset(3, 3),
      padding: EdgeInsets.symmetric(
        horizontal: unit * 0.7,
        vertical: unit * 0.5,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: ComicPalette.paper),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back,
              size: unit * 1.1,
              color: ComicPalette.paper,
            ),
            SizedBox(width: unit * 0.35),
            Text(
              Strings.menuLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: unit * 0.85,
                color: ComicPalette.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
