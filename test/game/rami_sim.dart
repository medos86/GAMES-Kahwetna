// Simulation de parties Rami pour mesurer les niveaux IA (issue #305).
// Partagé par le garde-fou rapide (test/game/rami_levels_smoke_test.dart, en CI)
// et la calibration nocturne (calibration/rami_win_rate_test.dart).
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/rami.dart';

const int ramiSimTargetScore = 100;
const int _maxSteps = 20000;

/// Générateur pseudo-aléatoire à graine fixe (congruentiel linéaire).
RandomDouble _seeded(int seed) {
  var s = seed;
  return () {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x80000000;
  };
}

/// Joue un match complet à quatre. [levelSeat] joue au niveau [level], les trois autres au moyen.
/// Retourne le siège vainqueur du match.
int playRamiMatch(RamiAiLevel level, int levelSeat, int seed) {
  final rnd = _seeded(seed);
  var state = newMatch(ramiSimTargetScore, rnd);
  var steps = 0;
  while (state.matchWinner == null) {
    if (++steps > _maxSteps) {
      throw StateError('match non terminé (graine $seed)');
    }
    if (state.phase == RamiPhase.end) {
      state = nextRound(state, rnd);
      continue;
    }
    final lvl = state.turn == levelSeat ? level : RamiAiLevel.moyen;
    final before = state;
    state = aiStep(state, lvl, rnd);
    if (identical(state, before)) {
      throw StateError('IA bloquée (graine $seed)');
    }
  }
  return state.matchWinner!;
}

/// Part des matchs gagnés par le niveau [level], sièges alternés pour éviter le biais de donne.
double ramiWinRate(RamiAiLevel level, {required int games}) {
  var wins = 0;
  for (var seed = 0; seed < games; seed++) {
    final levelSeat = seed % ramiSeats.length;
    if (playRamiMatch(level, levelSeat, seed + 1) == levelSeat) wins++;
  }
  return wins / games;
}
