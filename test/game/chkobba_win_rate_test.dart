// Mesure des niveaux IA Chkobba (issue #92) : 2 000 parties par niveau, chacune contre le niveau moyen
// (référence). Les places sont alternées une partie sur deux pour éviter le biais de donne.
// Cibles : facile ~30 %, moyen ~50 %, difficile ~90 %. Mesure seule : les écarts sont affichés, pas bloquants.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

const _games = 2000;
const _targetScore = 11;

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
Player _playGame(ChkobbaAiLevel level, Player levelSeat, int seed) {
  final rnd = _seeded(seed);
  var state = newMatch(targetScore: _targetScore, random: rnd);
  var steps = 0;
  while (state.winner == null) {
    if (++steps > 20000) {
      fail('partie non terminée (graine $seed)');
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

/// Taux de victoire du niveau [level] contre le niveau moyen, places alternées.
double _winRate(ChkobbaAiLevel level) {
  var wins = 0;
  for (var i = 0; i < _games; i++) {
    final levelSeat = i.isEven ? Player.opponent : Player.player;
    if (_playGame(level, levelSeat, i + 1) == levelSeat) wins++;
  }
  return wins / _games;
}

void main() {
  group('Chkobba : taux de victoire des niveaux IA (issue #92)', () {
    final targets = {
      ChkobbaAiLevel.facile: 0.30,
      ChkobbaAiLevel.moyen: 0.50,
      ChkobbaAiLevel.difficile: 0.90,
    };

    for (final entry in targets.entries) {
      final level = entry.key;
      final target = entry.value;
      final pct = (target * 100).round();
      // Mesure seule (issue #92) : l'écart à la cible est affiché, sans faire échouer la CI.
      test('niveau ${level.name} : mesure contre moyen', () {
        final rate = _winRate(level);
        final measured = (rate * 100).toStringAsFixed(1);
        print(
          'Chkobba ${level.name} : $measured % sur $_games parties (cible $pct %)',
        );
      });
    }
  });
}
