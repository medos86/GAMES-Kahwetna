import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

// Diagnostic temporaire du blocage IA (graine 3).
void main() {
  test('diagnostic partie IA graine 3', () {
    final rng = math.Random(3).nextDouble;
    var state = newMatch(100, rng);
    var steps = 0;
    var rounds = 0;
    var roundSteps = 0;
    final recent = <String>[];
    while (state.matchWinner == null && steps < 20000) {
      steps++;
      roundSteps++;
      if (state.phase == RamiPhase.end) {
        print('MANCHE $rounds fin en $roundSteps pas');
        print('  ouvertures=${state.openings} ouverts=${state.opened}');
        rounds++;
        roundSteps = 0;
        state = nextRound(state, rng);
        continue;
      }
      final before = state;
      state = aiStep(state, RamiAiLevel.difficile, rng);
      final same = identical(state, before);
      final main = state.hands.map((h) => h.length).toList();
      recent.add('${state.phase.name} tour=${state.turn} main=$main '
          'pioche=${state.stock.length} def=${state.discard.length} '
          'posés=${state.table.length} staged=${state.staged.length} '
          'lastOp=${state.lastOpening} same=$same');
      if (recent.length > 12) recent.removeAt(0);
    }
    print('FIN steps=$steps manches=$rounds gagnant=${state.matchWinner}');
    for (final line in recent) {
      print('  $line');
    }
  });
}
