// Tapis qui s'allume sur les prises possibles dès qu'une carte de la main est tenue (#923).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state() => ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: [
          _card(ChkobbaSuit.batons, 5),
          _card(ChkobbaSuit.batons, 3),
        ],
        Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
      },
      table: [
        _card(ChkobbaSuit.coupes, 5),
        _card(ChkobbaSuit.deniers, 9),
      ],
      won: {Player.player: [], Player.opponent: []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
      lastCapturer: null,
      turn: Player.player,
      starter: Player.player,
      round: 1,
      winner: null,
    );

void main() {
  test('rien ne s\'allume sans carte tenue', () {
    expect(chkobbaCaptureTargetIds(_state(), Player.player, null), isEmpty);
  });

  test('la carte tenue allume ses seules prises', () {
    expect(
      chkobbaCaptureTargetIds(_state(), Player.player, 'batons-5'),
      {'coupes-5'},
    );
  });

  test('une carte sans prise n\'allume rien', () {
    expect(
      chkobbaCaptureTargetIds(_state(), Player.player, 'batons-3'),
      isEmpty,
    );
  });

  test('une carte absente de la main n\'allume rien', () {
    expect(
      chkobbaCaptureTargetIds(_state(), Player.player, 'epees-7'),
      isEmpty,
    );
  });
}
