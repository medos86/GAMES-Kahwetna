import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';
import 'package:kahwetne/game/rami.dart';

/// Issue #316 : pioche et défausse des adversaires sont détectées pour les animer.
void main() {
  RamiCard c(String id) => RamiCard(id: id, suit: RamiSuit.epees, rank: 3);

  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0).copyWith(
    phase: RamiPhase.play,
    turn: 1,
    stock: [c('s1'), c('s2')],
    discard: [c('d1')],
  );

  test('adversaire qui pioche dans la pioche', () {
    final next = base.copyWith(stock: [c('s1')]);
    expect(ramiAiMoves(base, next), [RamiAiMove.drawStock]);
  });

  test('adversaire qui prend la défausse', () {
    final next = base.copyWith(discard: []);
    expect(ramiAiMoves(base, next), [RamiAiMove.takeDiscard]);
  });

  test('adversaire qui défausse', () {
    final next = base.copyWith(discard: [c('d1'), c('x')]);
    expect(ramiAiMoves(base, next), [RamiAiMove.discard]);
  });

  test('pas d\'animation pendant son propre tour', () {
    final mine = base.copyWith(turn: 0, stock: [c('s1')]);
    expect(ramiAiMoves(mine, mine.copyWith(discard: [])), isEmpty);
  });

  test('rien ne bouge dans la pioche ni la défausse', () {
    expect(ramiAiMoves(base, base.copyWith(turn: 2)), isEmpty);
  });
}
