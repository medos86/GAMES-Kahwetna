// Issue #440 : difficulté Coinche (compte des atouts tombés, atout maître).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

CoincheCard _card(CoincheSuit suit, CoincheRank rank) =>
    CoincheCard(suit: suit, rank: rank, id: '${suit.name}-${rank.label}');

Play _play(Seat seat, CoincheCard card) => Play(seat: seat, card: card);

/// Trois autres sièges sans carte, pour ne tester que la main de [Seat.south].
Map<Seat, List<CoincheCard>> _hands(List<CoincheCard> south) => {
      Seat.south: south,
      Seat.west: <CoincheCard>[],
      Seat.north: <CoincheCard>[],
      Seat.east: <CoincheCard>[],
    };

RoundState _playing({
  required Map<Seat, List<CoincheCard>> hands,
  List<Play> trick = const [],
  List<CoincheCard> played = const [],
}) {
  return RoundState(
    dealer: Seat.east,
    phase: CoinchePhase.playing,
    hands: hands,
    turn: Seat.south,
    calls: const {},
    contract: const Contract(
      seat: Seat.east,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    ),
    passes: 0,
    trick: trick,
    tricksPlayed: 0,
    tricksWon: {Team.ns: 0, Team.ew: 0},
    pointsWon: {Team.ns: 0, Team.ew: 0},
    lastWinner: null,
    belote: null,
    played: played,
  );
}

void main() {
  final valet = _card(CoincheSuit.coupes, CoincheRank.valet);
  final nine = _card(CoincheSuit.coupes, CoincheRank.nine);
  final ace = _card(CoincheSuit.coupes, CoincheRank.ace);
  final seven = _card(CoincheSuit.coupes, CoincheRank.seven);
  final aceDeniers = _card(CoincheSuit.deniers, CoincheRank.ace);

  group('atouts tombés (#440)', () {
    test('collectTrick enregistre les cartes du pli dans played', () {
      final trick = [
        _play(Seat.south, ace),
        _play(Seat.west, _card(CoincheSuit.deniers, CoincheRank.seven)),
        _play(Seat.north, _card(CoincheSuit.epees, CoincheRank.eight)),
        _play(Seat.east, _card(CoincheSuit.batons, CoincheRank.nine)),
      ];
      final round = _playing(hands: _hands(const []), trick: trick);
      final after = collectTrick(round);
      expect(after.played.length, 4);
      expect(after.played.first.rank, CoincheRank.ace);
    });

    test('played survit au aller-retour JSON, et vaut vide si absent', () {
      final round = _playing(hands: _hands(const []), played: [valet]);
      final back = RoundState.fromJson(round.toJson());
      expect(back.played.single.rank, CoincheRank.valet);

      final json = round.toJson()..remove('played');
      expect(RoundState.fromJson(json).played, isEmpty);
    });

    test('unseenTrumps exclut la main, les cartes jouées et le pli', () {
      final round = _playing(
        hands: _hands([valet]),
        played: [nine],
        trick: [_play(Seat.west, ace)],
      );
      final unseen = unseenTrumps(round, Seat.south, CoincheSuit.coupes);
      expect(unseen.length, 5);
      final ranks = unseen.map((c) => c.rank).toSet();
      expect(ranks.contains(CoincheRank.valet), isFalse);
      expect(ranks.contains(CoincheRank.nine), isFalse);
      expect(ranks.contains(CoincheRank.ace), isFalse);
      expect(unseen.every((c) => c.suit == CoincheSuit.coupes), isTrue);
    });
  });

  group('atout maître (#440)', () {
    test('valet d\'atout en main sans atout plus fort dehors = maître', () {
      final round = _playing(hands: _hands([valet]));
      final master = masterTrump(round, Seat.south, CoincheSuit.coupes);
      expect(master?.rank, CoincheRank.valet);
    });

    test('un atout plus fort encore dehors empêche le maître', () {
      final round = _playing(hands: _hands([seven]));
      expect(masterTrump(round, Seat.south, CoincheSuit.coupes), isNull);
    });

    test('difficile mène le maître quand des atouts sont encore dehors', () {
      final round = _playing(hands: _hands([valet, aceDeniers]));
      final id = chooseCard(
        round,
        Seat.south,
        false,
        () => 0.99,
        CoincheAiLevel.difficile,
      );
      expect(id, valet.id);
    });

    test('moyen ne mène pas le maître (comportement inchangé)', () {
      final round = _playing(hands: _hands([valet, aceDeniers]));
      final id = chooseCard(
        round,
        Seat.south,
        false,
        () => 0.99,
        CoincheAiLevel.moyen,
      );
      expect(id, isNot(valet.id));
    });
  });
}
