import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

// Diagnostic temporaire du blocage IA (graine 3) : affiche l'état quand la partie ne finit pas.
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
        print('manche $rounds finie en $roundSteps pas, ouvertures=${state.openings} '
            'ouverts=${state.opened} scores=${state.scores}');
        rounds++;
        roundSteps = 0;
        state = nextRound(state, rng);
        continue;
      }
      final before = state;
      state = aiStep(state, RamiAiLevel.difficile, rng);
      recent.add('phase=${state.phase.name} tour=${state.turn} '
          'main=${state.hands.map((h) => h.length).toList()} '
          'pioche=${state.stock.length} défausse=${state.discard.length} '
          'posés=${state.table.length} staged=${state.staged.length} '
          'lastOpening=${state.lastOpening} identique=${identical(state, before)}');
      if (recent.length > 12) recent.removeAt(0);
    }
    print('FIN steps=$steps rounds=$rounds winner=${state.matchWinner} '
        'lastOpening=${state.lastOpening} openings=${state.openings}');
    for (final line in recent) {
      print('  $line');
    }
  });
}
