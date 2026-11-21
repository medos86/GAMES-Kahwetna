// Issue #720 : harnais de simulation Coinche (parties complètes, 32 cartes jouées).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

import 'coinche_sim.dart';

void main() {
  group('Coinche : harnais de simulation (issue #720)', () {
    test('une partie complète se termine, sans boucle infinie', () {
      for (var seed = 1; seed <= 20; seed++) {
        final winner = playCoincheMatch(
          CoincheAiLevel.difficile,
          Team.ns,
          seed,
        );
        expect(Team.values, contains(winner), reason: 'graine $seed');
      }
    });

    test("une donne jouée jusqu'au bout couvre les 32 cartes", () {
      final everyCard = {
        for (final suit in CoincheSuit.values)
          for (final rank in CoincheRank.values) '${suit.name}-${rank.label}',
      };
      expect(everyCard, hasLength(32));

      var played = 0;
      for (var seed = 1; played < 10 && seed < 500; seed++) {
        final dealt = dealRound(Seat.south, math.Random(seed).nextDouble);
        final round = simPlayRound(
          dealt,
          Team.ns,
          CoincheAiLevel.moyen,
          math.Random(seed).nextDouble,
        );
        if (round.phase != CoinchePhase.done) continue;
        played++;
        expect(round.played, hasLength(32), reason: 'graine $seed');
        expect(
          {for (final c in round.played) c.id},
          everyCard,
          reason: 'graine $seed',
        );
      }
      expect(played, 10, reason: 'trop peu de donnes jouées');
    });
  });
}
