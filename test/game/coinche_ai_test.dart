import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

void main() {
  test('difficile n\'annonce jamais avec moins de trois atouts', () {
    for (var seed = 0; seed < 300; seed++) {
      final round = dealRound(Seat.east, math.Random(seed).nextDouble);
      final action = chooseBid(round, Seat.south, CoincheAiLevel.difficile);
      if (action is ValueBid) {
        final trumps =
            round.hands[Seat.south]!.where((c) => c.suit == action.mode).length;
        expect(trumps, greaterThanOrEqualTo(3), reason: 'seed $seed');
      }
    }
  });

  RoundState playRound(int seed) => dealRound(
        Seat.east,
        math.Random(seed).nextDouble,
      ).copyWith(
        phase: CoinchePhase.playing,
        contract: const Contract(
          seat: Seat.east,
          value: 80,
          mode: CoincheSuit.coupes,
          multiplier: 1,
        ),
        turn: Seat.south,
      );

  test('facile joue toujours une carte légale (#282)', () {
    for (var seed = 0; seed < 40; seed++) {
      final round = playRound(seed);
      final legal = legalCards(round, Seat.south).map((c) => c.id);
      for (var i = 0; i < 20; i++) {
        final id = chooseCard(
          round,
          Seat.south,
          true,
          () => i / 20,
          CoincheAiLevel.facile,
        );
        expect(legal, contains(id));
      }
    }
  });

  test('facile = moyen hors bruit : tirage au-dessus du seuil (#282)', () {
    for (var seed = 0; seed < 40; seed++) {
      final round = playRound(seed);
      final facile = chooseCard(
        round,
        Seat.south,
        true,
        () => 0.99,
        CoincheAiLevel.facile,
      );
      final moyen = chooseCard(
        round,
        Seat.south,
        false,
        () => 0.99,
        CoincheAiLevel.moyen,
      );
      expect(facile, moyen);
    }
  });
}
