import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';

/// En-tête commun des écrans de jeu (#242).
///
/// Bouton Menu à gauche, emplacement à droite (trophée, règles…). Pas de titre
/// ni de sous-titre : ils sont retirés des écrans de jeu (#223). La position ne
/// dépend ni du jeu ni de la langue.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.onMenu,
    this.trailing,
  });

  final VoidCallback onMenu;
  final Widget? trailing;

  /// Hauteur minimale de la zone tactile, en dp.
  static const double touchSize = 44;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: Strings.menuLabel,
          child: TextButton.icon(
            onPressed: onMenu,
            icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFFFFF1BD)),
            label: Text(
              Strings.menuLabel,
              style: const TextStyle(color: Color(0xFFFFF1BD), fontWeight: FontWeight.w800),
            ),
            style: TextButton.styleFrom(minimumSize: const Size(touchSize, touchSize)),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
