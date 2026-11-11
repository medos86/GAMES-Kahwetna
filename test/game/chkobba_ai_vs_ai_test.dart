// Partie complète Chkobba jouée par la logique pure (issue #20) : aucune exception, aucune carte perdue,
// et la partie finit. Le joueur humain prend la première carte de sa main (prise par défaut),
// l'adversaire joue selon le niveau testé. Graine fixe : le test est reproductible.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

/// Générateur pseudo-aléatoire à graine fixe (congruentiel linéaire).
RandomDouble seeded(int seed) {
  var s = seed;
  return () {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x80000000;
  };
}

/// Les 40 cartes doivent toujours être quelque part : main, tapis, pioche ou cartes ramassées.
int cardCount(ChkobbaState s) =>
    s.hands.values.fold(0, (a, h) => a + h.length) +
    s.table.length +
    s.deck.length +
    s.won.values.fold(0, (a, w) => a + w.length);

ChkobbaState playMatch(ChkobbaAiLevel level, int seed) {
  final rnd = seeded(seed);
  var state = newMatch(targetScore: 11, random: rnd);
  var steps = 0;
  while (state.winner == null) {
    steps++;
    if (steps > 20000) fail('partie non terminée (graine $seed, niveau ${level.name})');
    expect(cardCount(state), 40, reason: 'cartes perdues ou dupliquées (graine $seed)');

    if (state.hands[Player.player]!.isEmpty && state.hands[Player.opponent]!.isEmpty) {
      if (state.deck.isNotEmpty) {
        state = dealHands(state);
        continue;
      }
      state = scoreRound(state).state;
      if (state.winner != null) break;
      state = dealRound(
        scores: state.scores,
        starter: other(state.starter),
        round: state.round + 1,
        targetScore: state.targetScore,
        random: rnd,
      );
      continue;
    }

    final who = state.turn;
    if (state.hands[who]!.isEmpty) fail('tour sans carte en main (graine $seed)');
    if (who == Player.opponent) {
      final move = chooseOpponentMove(state, level, random: rnd);
      state = playCard(state, who, move.cardId, discardOnly: !move.capture).state;
    } else {
      state = playCard(state, who, state.hands[who]!.first.id).state;
    }
  }
  return state;
}

void main() {
  group('Chkobba : parties IA contre joueur, sans exception (issue #20)', () {
    for (final level in ChkobbaAiLevel.values) {
      test('niveau ${level.name} : cinq parties complètes, sans carte perdue', () {
        for (var seed = 1; seed <= 5; seed++) {
          final end = playMatch(level, seed);
          expect(end.winner, isNotNull);
          expect(cardCount(end), 40);
        }
      });
    }
  });
}
