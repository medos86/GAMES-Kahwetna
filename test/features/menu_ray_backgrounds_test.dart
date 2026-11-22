import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

// Fonds « rayons » pop-art : chaque jeu utilise un fichier rays_ existant.
void main() {
  const raysGames = ['Chkobba', 'Domino', 'Belote', 'Ludo', 'Rami'];

  test('chaque jeu à fond rayons pointe vers un fichier existant', () {
    for (final name in raysGames) {
      final game = gameEntries.firstWhere((g) => g.name == name);
      expect(game.backgroundAsset, contains('/rays_'),
          reason: '$name doit avoir un fond rayons');
      expect(File(game.backgroundAsset).existsSync(), isTrue,
          reason: 'fichier absent : ${game.backgroundAsset}');
    }
  });
}
