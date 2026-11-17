// Simulation de parties Ludo pour mesurer les niveaux IA (issue #305).
// Partagé par le garde-fou rapide (test/game/ludo_levels_smoke_test.dart, en CI)
// et la calibration nocturne (calibration/ludo_win_rate_test.dart).
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/ludo.dart';

const int _maxSteps = 20000;

/// Générateur pseudo-aléatoire à graine fixe (congruentiel linéaire).
RandomDouble _seeded(int seed) {
  var s = seed;
  return () {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x80000000;
  };
}

/// Joue une partie à quatre. [levelColor] joue au niveau [level], les trois autres au moyen.
/// Retourne la couleur classée première.
LudoColor playLudoGame(LudoAiLevel level, LudoColor levelColor, int seed) {
  final rnd = _seeded(seed);
  var state = newLudoGame();
  var steps = 0;
  while (state.phase != LudoPhase.end) {
    if (++steps > _maxSteps) {
      throw StateError('partie non terminée (graine $seed)');
    }
    final lvl = state.turn == levelColor ? level : LudoAiLevel.moyen;
    if (state.phase == LudoPhase.roll) {
      state = rollDice(state, rnd, lvl);
      continue;
    }
    final id = chooseMove(state, lvl, rnd);
    if (id == null) {
      throw StateError('aucun coup en phase move (graine $seed)');
    }
    state = moveToken(state, id);
  }
  return state.rankings.first;
}

/// Part des parties gagnées (première place) par le niveau [level], rouge contre trois adversaires moyens.
double ludoWinRate(LudoAiLevel level, {required int games}) {
  var wins = 0;
  for (var seed = 0; seed < games; seed++) {
    if (playLudoGame(level, LudoColor.red, seed) == LudoColor.red) wins++;
  }
  return wins / games;
}
