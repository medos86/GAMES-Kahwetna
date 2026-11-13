import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

// Sérialisation des types du Coinche : sauvegarde et reprise de partie (#167).
void main() {
  test('carte : toJson puis fromJson redonne la même carte', () {
    const card = CoincheCard(
      suit: CoincheSuit.coupes,
      rank: CoincheRank.roi,
      id: 'c-roi',
    );
    final back = CoincheCard.fromJson(card.toJson());
    expect(back.suit, CoincheSuit.coupes);
    expect(back.rank, CoincheRank.roi);
    expect(back.id, 'c-roi');
  });

  test('pli : toJson contient le siège et la carte', () {
    const play = Play(
      seat: Seat.west,
      card: CoincheCard(
        suit: CoincheSuit.epees,
        rank: CoincheRank.ace,
        id: 'e-as',
      ),
    );
    final json = play.toJson();
    expect(json['seat'], 'west');
    expect(json['card'], isA<Map<String, dynamic>>());
    expect(Play.fromJson(json).seat, Seat.west);
  });

  test('contrat : multiplicateur changé, puis relu depuis le JSON', () {
    const contract = Contract(
      seat: Seat.north,
      value: 90,
      mode: CoincheSuit.batons,
      multiplier: 1,
    );
    final doubled = contract.withMultiplier(2);
    expect(doubled.multiplier, 2);
    final back = Contract.fromJson(doubled.toJson());
    expect(back.value, 90);
    expect(back.mode, CoincheSuit.batons);
    expect(back.multiplier, 2);
  });

  test('enchères : chaque type se relit depuis le JSON', () {
    expect(BidAction.fromJson({'type': 'pass'}), isA<PassBid>());
    expect(BidAction.fromJson({'type': 'contre'}), isA<ContreBid>());
    expect(BidAction.fromJson({'type': 'surcoinche'}), isA<SurcoincheBid>());
    final bid = BidAction.fromJson({
      'type': 'bid',
      'value': 100,
      'mode': 'deniers',
    });
    expect(bid, isA<ValueBid>());
    expect(bid.toJson(), {'type': 'bid', 'value': 100, 'mode': 'deniers'});
    expect(
      () => BidAction.fromJson({'type': 'inconnu'}),
      throwsFormatException,
    );
  });

  test('résultat de manche : toJson puis fromJson', () {
    const result = CoincheRoundResult(
      contract: Contract(
        seat: Seat.south,
        value: 80,
        mode: CoincheSuit.coupes,
        multiplier: 1,
      ),
      made: true,
      capot: false,
      points: {Team.ns: 100, Team.ew: 62},
      awarded: {Team.ns: 180, Team.ew: 0},
    );
    final json = result.toJson();
    final back = CoincheRoundResult.fromJson(json);
    expect(back.made, isTrue);
    expect(back.capot, isFalse);
    expect(back.points[Team.ns], 100);
    expect(back.awarded[Team.ns], 180);
    expect(back.toJson(), json);
  });

  test('partie : scores, gagnant et relecture du JSON', () {
    const match = CoincheMatch(
      target: 1000,
      scores: {Team.ns: 1010, Team.ew: 300},
      round: 7,
      winner: Team.ns,
    );
    final back = CoincheMatch.fromJson(match.toJson());
    expect(back.winner, Team.ns);
    expect(back.scores[Team.ew], 300);
    expect(back.round, 7);

    const ongoing = CoincheMatch(
      target: 1000,
      scores: {Team.ns: 0, Team.ew: 0},
      round: 1,
      winner: null,
    );
    expect(CoincheMatch.fromJson(ongoing.toJson()).winner, isNull);
  });

  test('donne : copyWith sans changement garde la même donne', () {
    final round = dealRound(Seat.south, () => 0.37);
    final copy = round.copyWith();
    expect(copy.toJson(), round.toJson());
  });
}
