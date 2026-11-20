import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';

/// Issue #555 : état d'avatar selon le gagnant de la manche de domino.
DominoState _state({Player? roundWinner}) {
  return DominoState(
    hands: const {Player.player: [], Player.opponent: []},
    boneyard: const [],
    chain: const [],
    leftEnd: null,
    rightEnd: null,
    scores: const {Player.player: 0, Player.opponent: 0},
    turn: Player.player,
    consecutivePasses: 0,
    roundWinner: roundWinner,
    matchWinner: null,
    pointsAwarded: 0,
    targetScore: 50,
    round: 1,
  );
}

void main() {
  test('manche en cours : avatars neutres', () {
    final game = _state();
    expect(dominoAvatarState(game, Player.player), AvatarState.neutral);
    expect(dominoAvatarState(game, Player.opponent), AvatarState.neutral);
  });

  test('fin de manche : gagnant heureux, adversaire fâché', () {
    final game = _state(roundWinner: Player.player);
    expect(dominoAvatarState(game, Player.player), AvatarState.happy);
    expect(dominoAvatarState(game, Player.opponent), AvatarState.angry);
  });
}
