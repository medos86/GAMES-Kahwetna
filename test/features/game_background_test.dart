import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

GameEntry _byName(String name) => gameEntries.firstWhere((g) => g.name == name);

// Fond photo par jeu sur l'écran de choix du niveau (#335).
void main() {
  test('Chkobba, Domino et Belote ont chacun leur photo', () {
    expect(
      _byName('Chkobba').backgroundAsset,
      'assets/images/game_bg/chkobba_sfax.webp',
    );
    expect(
      _byName('Domino').backgroundAsset,
      'assets/images/game_bg/domino_medina_tunis.webp',
    );
    expect(
      _byName('Belote').backgroundAsset,
      'assets/images/game_bg/coinche_kairouan.webp',
    );
  });

  test('les photos référencées existent dans les assets', () {
    for (final game in gameEntries) {
      if (game.backgroundAsset == kMenuBackgroundAsset) continue;
      expect(
        File(game.backgroundAsset).existsSync(),
        isTrue,
        reason: game.backgroundAsset,
      );
    }
  });

  test('les trois photos sont distinctes', () {
    final assets = {
      _byName('Chkobba').backgroundAsset,
      _byName('Domino').backgroundAsset,
      _byName('Belote').backgroundAsset,
    };
    expect(assets.length, 3);
  });

  test('Ludo et Rami gardent le fond commun', () {
    expect(_byName('Ludo').backgroundAsset, kMenuBackgroundAsset);
    expect(_byName('Rami').backgroundAsset, kMenuBackgroundAsset);
  });
}
