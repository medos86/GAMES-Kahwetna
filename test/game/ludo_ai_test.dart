import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('difficile choisit toujours un coup légal, sur des lancers variés', () {
    for (var seed = 0; seed < 60; seed++) {
      final rng = math.Random(seed);
      final rolled = rollDice(newLudoGame(), rng.nextDouble);
      final legal = legalTokenIds(rolled);
      if (legal.isEmpty) continue;
      expect(legal, contains(chooseMove(rolled, LudoAiLevel.difficile)));
    }
  });

  test(
    'facile choisit toujours un coup légal, quel que soit le tirage (#279)',
    () {
      for (var seed = 0; seed < 60; seed++) {
        final rng = math.Random(seed);
        final rolled = rollDice(newLudoGame(), rng.nextDouble);
        final legal = legalTokenIds(rolled);
        if (legal.isEmpty) continue;
        for (var i = 0; i < 20; i++) {
          expect(
            legal,
            contains(chooseMove(rolled, LudoAiLevel.facile, () => i / 20)),
          );
        }
      }
    },
  );

  test(
    'facile = moyen hors bruit : tirage au-dessus du seuil (#279)',
    () {
      for (var seed = 0; seed < 60; seed++) {
        final rng = math.Random(seed);
        final rolled = rollDice(newLudoGame(), rng.nextDouble);
        if (legalTokenIds(rolled).isEmpty) continue;
        expect(
          chooseMove(rolled, LudoAiLevel.facile, () => 0.99),
          chooseMove(rolled, LudoAiLevel.moyen, () => 0.99),
        );
      }
    },
  );

  test(
    'facile joue au hasard sous le seuil de bruit (#279)',
    () {
      // Tirage à 0 : bruit déclenché, premier pion légal choisi.
      final rolled = rollDice(newLudoGame(), () => 0.5);
      final legal = legalTokenIds(rolled);
      if (legal.isEmpty) return;
      expect(chooseMove(rolled, LudoAiLevel.facile, () => 0.0), legal.first);
    },
  );
}
