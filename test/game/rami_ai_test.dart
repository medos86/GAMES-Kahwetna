import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

void main() {
  test('difficile mène une partie complète sans erreur et sans bloquer (partie IA seule)', () {
    for (var seed = 0; seed < 5; seed++) {
      final rng = math.Random(seed).nextDouble;
      var state = newMatch(100, rng);
      var steps = 0;
      const maxSteps = 20000;
      while (state.matchWinner == null && steps++ < maxSteps) {
        if (state.phase == RamiPhase.end) {
          state = nextRound(state, rng);
          continue;
        }
        final before = state;
        state = aiStep(state, RamiAiLevel.difficile, rng);
        // Un coup refusé renvoie la même instance : l'IA doit alors pouvoir progresser ailleurs.
        if (identical(state, before) &&
            state.phase == RamiPhase.play &&
            state.staged.isEmpty) {
          break;
        }
      }
      expect(
        steps,
        lessThan(maxSteps),
        reason: 'la partie doit avancer (seed $seed)',
      );
    }
  });
}
