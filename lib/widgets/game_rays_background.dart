import 'package:flutter/widgets.dart';

import '../features/menu/menu_models.dart';

/// Fond des écrans de jeu : les rayons propres à chaque jeu (#804).
/// C'est la même image que l'écran de choix du niveau (`GameEntry.backgroundAsset`).
class GameRaysBackground extends StatelessWidget {
  const GameRaysBackground({super.key, required this.gameName});

  /// Nom du jeu tel qu'il figure dans [gameEntries] (ex. « Chkobba »).
  final String gameName;

  /// Asset des rayons du jeu ; lève une erreur si le jeu est inconnu.
  static String assetFor(String gameName) =>
      gameEntries.firstWhere((g) => g.name == gameName).backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetFor(gameName),
      key: ValueKey(gameName),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
    );
  }
}
