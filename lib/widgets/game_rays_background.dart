import 'package:flutter/widgets.dart';

import '../features/menu/menu_models.dart';
import 'texture_patterns.dart';

/// Fond des écrans de jeu (#821) : dégradé aux couleurs du jeu + trame de points.
/// Plus de rayons : les lignes fatiguaient la vue.
class GameRaysBackground extends StatelessWidget {
  const GameRaysBackground({super.key, required this.gameName});

  /// Nom du jeu tel qu'il figure dans [gameEntries] (ex. « Chkobba »).
  final String gameName;

  /// Entrée du jeu ; lève une erreur si le jeu est inconnu.
  static GameEntry entryFor(String gameName) =>
      gameEntries.firstWhere((g) => g.name == gameName);

  /// Asset historique des rayons (conservé pour l'écran de choix du niveau).
  static String assetFor(String gameName) => entryFor(gameName).backgroundAsset;

  @override
  Widget build(BuildContext context) {
    final entry = entryFor(gameName);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.1,
              colors: [entry.gradientFrom, entry.gradientTo],
            ),
          ),
        ),
        const Positioned.fill(
          child: DotPattern(
            spacing: 18,
            radius: 1.5,
            color: Color(0x26FFFFFF),
          ),
        ),
      ],
    );
  }
}
