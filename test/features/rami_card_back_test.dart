import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/game/rami.dart';

/// Issue #372 : chaque jeu de 52 cartes a son dos (bleu pour le jeu 0, rouge pour le jeu 1).
void main() {
  const blue = RamiCard(id: 'epees-7-0', suit: RamiSuit.epees, rank: 7);
  const red = RamiCard(id: 'epees-7-1', suit: RamiSuit.epees, rank: 7);
  const joker = RamiCard(id: 'joker-0', suit: null, rank: 0);

  test('le jeu 0 a le dos bleu, le jeu 1 le dos rouge', () {
    expect(ramiBackAssetOf(blue), ramiCardBackBlueAsset);
    expect(ramiBackAssetOf(red), ramiCardBackAsset);
  });

  test('un joker ou une carte absente garde le dos rouge', () {
    expect(ramiBackAssetOf(joker), ramiCardBackAsset);
    expect(ramiBackAssetOf(null), ramiCardBackAsset);
  });

  test('la pioche montre le dos de la carte du dessus', () {
    expect(ramiStockBackAsset([red, blue]), ramiCardBackBlueAsset);
    expect(ramiStockBackAsset([blue, red]), ramiCardBackAsset);
    expect(ramiStockBackAsset(const []), ramiCardBackAsset);
  });

  test('les deux dos existent dans les assets', () {
    expect(File(ramiCardBackBlueAsset).existsSync(), isTrue);
    expect(File(ramiCardBackAsset).existsSync(), isTrue);
  });
}
