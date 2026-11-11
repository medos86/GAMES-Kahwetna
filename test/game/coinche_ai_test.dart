import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

void main() {
  test('difficile n\'annonce jamais avec moins de trois atouts', () {
    for (var seed = 0; seed < 300; seed++) {
      final round = dealRound(Seat.east, math.Random(seed).nextDouble);
      final action = chooseBid(round, Seat.south, CoincheAiLevel.difficile);
      if (action is ValueBid) {
        final trumps = round.hands[Seat.south]!.where((c) => c.suit == action.mode).length;
        expect(trumps, greaterThanOrEqualTo(3), reason: 'seed $seed');
      }
    }
  });
}
