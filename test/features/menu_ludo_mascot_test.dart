import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/mascot_outline.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

// Mascotte Ludo affichée sur l'écran principal (#928).
void main() {
  test('Ludo a une mascotte PNG détourée comme les autres jeux', () {
    final ludo = gameEntries.firstWhere((g) => g.isLudo);
    expect(ludo.photoAsset, 'assets/images/mascots/ludo.png');
    expect(File(ludo.photoAsset!).existsSync(), isTrue);
    for (final game in gameEntries.where((g) => !g.isLudo)) {
      expect(game.photoAsset, isNotNull, reason: game.name);
    }
  });

  test('la mascotte Ludo a un contour pour la pointe lumineuse', () {
    expect(mascotOutlineFor('assets/images/mascots/ludo.png'), isNotNull);
  });
}
