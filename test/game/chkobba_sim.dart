// Simulation de parties Chkobba pour mesurer les niveaux IA (issue #92).
// Partagé par le garde-fou rapide (test/game/chkobba_levels_smoke_test.dart, en CI)
// et la calibration nocturne (calibration/chkobba_win_rate_test.dart).
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

const int chkobbaSimTargetScore = 11;

/// Générateur pseudo-aléatoire à graine fixe (congruentiel linéaire).
RandomDouble _seeded(int seed) {
  var s = seed;
  return () {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x80000000;
  };
}

Player _other(Player p) => p == Player.player ? Player.opponent : Player.player;

/// Coup du siège [seat] selon [level]. [chooseOpponentMove] ne décide que pour l'adversaire :
/// pour le joueur, on inverse les mains et les tas ramassés pour que l'IA se voie comme adversaire.
ChkobbaAiMove _aiMove(
  ChkobbaState s,
  Player seat,
  ChkobbaAiLevel level,
  RandomDouble rnd,
) {
  if (seat == Player.opponent) {
    return chooseOpponentMove(s, level, random: rnd);
  }
  final mirrored = s.copyWith(
    hands: {
      Player.player: s.hands[Player.opponent]!,
      Player.opponent: s.hands[Player.player]!,
    },
    won: {
      Player.player: s.won[Player.opponent]!,
      Player.opponent: s.won[Player.player]!,
    },
  );
  return chooseOpponentMove(mirrored, level, random: rnd);
}

/// Joue une partie complète. [levelSeat] joue au niveau [level], l'autre siège au niveau moyen.
/// Retourne le vainqueur.
Player playChkobbaGame(ChkobbaAiLevel level, Player levelSeat, int seed) {
  final rnd = _seeded(seed);
  var state = newMatch(targetScore: chkobbaSimTargetScore, random: rnd);
  var steps = 0;
  while (state.winner == null) {
    if (++steps > 20000) {
      throw StateError('partie non terminée (graine $seed)');
    }
    if (state.hands[Player.player]!.isEmpty &&
        state.hands[Player.opponent]!.isEmpty) {
      if (state.deck.isNotEmpty) {
        state = dealHands(state);
        continue;
      }
      state = scoreRound(state).state;
      if (state.winner != null) break;
      state = dealRound(
        scores: state.scores,
        starter: _other(state.starter),
        round: state.round + 1,
        targetScore: state.targetScore,
        random: rnd,
      );
      continue;
    }

    final who = state.turn;
    final seatLevel = who == levelSeat ? level : ChkobbaAiLevel.moyen;
    final move = _aiMove(state, who, seatLevel, rnd);
    state = playCard(
      state,
      who,
      move.cardId,
      discardOnly: !move.capture,
    ).state;
  }
  return state.winner!;
}

/// Taux de victoire de [level] contre le niveau moyen, places alternées une partie sur deux.
double chkobbaWinRate(ChkobbaAiLevel level, {required int games}) {
  var wins = 0;
  for (var i = 0; i < games; i++) {
    final levelSeat = i.isEven ? Player.opponent : Player.player;
    if (playChkobbaGame(level, levelSeat, i + 1) == levelSeat) wins++;
  }
  return wins / games;
}
