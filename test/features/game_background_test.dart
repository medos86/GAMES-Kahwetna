import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

GameEntry _byName(String name) => gameEntries.firstWhere((g) => g.name == name);

// Fond rayons pop-art par jeu sur l'écran de choix du niveau (#781).
void main() {
  test('chaque jeu a son fond rayons', () {
    expect(
      _byName('Chkobba').backgroundAsset,
      'assets/images/game_bg/rays_chkobba.webp',
    );
    expect(
      _byName('Domino').backgroundAsset,
      'assets/images/game_bg/rays_domino.webp',
    );
    expect(
      _byName('Belote').backgroundAsset,
      'assets/images/game_bg/rays_belote.webp',
    );
    expect(
      _byName('Ludo').backgroundAsset,
      'assets/images/game_bg/rays_ludo.webp',
    );
    expect(
      _byName('Rami').backgroundAsset,
      'assets/images/game_bg/rays_rami.webp',
    );
  });

  test('les fonds référencés existent dans les assets', () {
    for (final game in gameEntries) {
      expect(
        File(game.backgroundAsset).existsSync(),
        isTrue,
        reason: game.backgroundAsset,
      );
    }
  });

  test('les fonds des cinq jeux sont distincts', () {
    final assets = {for (final g in gameEntries) g.backgroundAsset};
    expect(assets.length, gameEntries.length);
  });
}
