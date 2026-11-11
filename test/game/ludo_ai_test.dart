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
}
