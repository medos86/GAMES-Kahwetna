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
/// Retourne le siège vainqueur. Lève une erreur détaillée si l'IA se bloque.
int playRamiMatch(RamiAiLevel level, int levelSeat, int seed) {
  final rnd = _seeded(seed);
  var state = newMatch(ramiSimTargetScore, rnd);
  var steps = 0;
  final trace = <String>[];
  while (state.matchWinner == null) {
    if (++steps > _maxSteps) {
      final tail = trace.sublist(trace.length > 12 ? trace.length - 12 : 0);
      throw StateError(
        'match non terminé (graine $seed, niveau ${level.name}, siège $levelSeat) : '
        'manche ${state.round}, scores ${state.scores}, cible ${state.targetScore}, '
        'phase ${state.phase}, pioche ${state.stock.length}, '
        'défausse ${state.discard.length}, table ${state.table.length}, '
        'ouverts ${state.opened}, premierTour ${state.firstTour}, '
        'mains ${state.hands.map((h) => h.length).toList()}\n'
        'trace: ${tail.join(' | ')}',
      );
    }
    if (state.phase == RamiPhase.end) {
      state = nextRound(state, rnd);
      continue;
    }
    final lvl = state.turn == levelSeat ? level : RamiAiLevel.moyen;
    final before = state;
    state = aiStep(state, lvl, rnd);
    trace.add(
      'j${before.turn}:${before.phase.name}->${state.phase.name} '
      'pris=${before.takenId} dessus=${before.discard.isEmpty ? '-' : before.discard.last.id} '
      'main=${state.hands[before.turn].length} ouvert=${state.opened[before.turn]}',
    );
    if (identical(state, before)) {
      final t = state.turn;
      throw StateError(
        'IA bloquée (graine $seed, niveau ${level.name}, siège $levelSeat) : '
        'phase ${state.phase}, tour $t, ouvert ${state.opened[t]}, '
        'premierTour ${state.firstTour}, pris ${state.takenId}, '
        'staged ${state.staged.length}, main ${state.hands[t].length} '
        '[${state.hands[t].map((c) => c.id).join(',')}], '
        'defausse ${state.discard.length}, pioche ${state.stock.length}, '
        'dessus ${state.discard.isEmpty ? '-' : state.discard.last.id}, '
        'table ${state.table.length}',
      );
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
