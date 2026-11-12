// Tests unitaires de lib/game/coinche.dart (guide §6.1, Coinche).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

CoincheCard card(CoincheSuit suit, CoincheRank rank) =>
    CoincheCard(suit: suit, rank: rank, id: '${suit.name}-${rank.label}');

/// Construit une manche précise, sans tirage aléatoire.
RoundState makeRound({
  Seat dealer = Seat.east,
  CoinchePhase phase = CoinchePhase.bidding,
  Map<Seat, List<CoincheCard>>? hands,
  Seat? turn,
  Contract? contract,
  int passes = 0,
  List<Play> trick = const [],
  int tricksPlayed = 0,
  Map<Team, int>? tricksWon,
  Map<Team, int>? pointsWon,
  Seat? lastWinner,
  Team? belote,
}) {
  return RoundState(
    dealer: dealer,
    phase: phase,
    hands: hands ?? {for (final s in Seat.values) s: <CoincheCard>[]},
    turn: turn ?? nextSeat(dealer),
    calls: const {},
    contract: contract,
    passes: passes,
    trick: trick,
    tricksPlayed: tricksPlayed,
    tricksWon: tricksWon ?? {Team.ns: 0, Team.ew: 0},
    pointsWon: pointsWon ?? {Team.ns: 0, Team.ew: 0},
    lastWinner: lastWinner,
    belote: belote,
  );
}

void main() {
  group('donne et sièges', () {
    test('dealRound distribue 8 cartes par siège, sans doublon', () {
      final round = dealRound(Seat.east, () => 0.5);
      for (final seat in Seat.values) {
        expect(round.hands[seat], hasLength(handSize));
      }
      final ids = round.hands.values.expand((h) => h).map((c) => c.id).toSet();
      expect(ids, hasLength(32));
      expect(
        round.turn,
        Seat.south,
      ); // premier annonceur = siège après le donneur
    });

    test('teamOf : sud et nord forment une équipe, ouest et est l\'autre', () {
      expect(teamOf(Seat.south), Team.ns);
      expect(teamOf(Seat.north), Team.ns);
      expect(teamOf(Seat.west), Team.ew);
      expect(teamOf(Seat.east), Team.ew);
    });
  });

  group('enchères', () {
    test('une enchère invalide renvoie l\'instance reçue', () {
      final round = makeRound(); // donneur est : premier annonceur sud
      expect(
        identical(
          placeBid(round, Seat.south, const ValueBid(70, CoincheSuit.deniers)),
          round,
        ),
        isTrue,
      );
      expect(
        identical(
          placeBid(round, Seat.south, const ValueBid(85, CoincheSuit.deniers)),
          round,
        ),
        isTrue,
      );
      expect(
        identical(
          placeBid(round, Seat.south, const ValueBid(170, CoincheSuit.deniers)),
          round,
        ),
        isTrue,
      );
    });

    test('jouer hors de son tour renvoie l\'instance reçue', () {
      final round = makeRound();
      expect(
        identical(placeBid(round, Seat.west, const PassBid()), round),
        isTrue,
      );
    });

    test('quatre passes sans contrat : nouvelle donne (redeal)', () {
      var round = makeRound();
      for (final seat in [Seat.south, Seat.west, Seat.north]) {
        round = placeBid(round, seat, const PassBid());
      }
      expect(round.phase, CoinchePhase.bidding);
      round = placeBid(round, Seat.east, const PassBid());
      expect(round.phase, CoinchePhase.redeal);
      expect(round.turn, isNull);
    });

    test(
        'trois passes après un contrat : phase de jeu, premier joueur = siège après le donneur',
        () {
      var round = makeRound();
      round = placeBid(
        round,
        Seat.south,
        const ValueBid(80, CoincheSuit.deniers),
      );
      round = placeBid(round, Seat.west, const PassBid());
      round = placeBid(round, Seat.north, const PassBid());
      round = placeBid(round, Seat.east, const PassBid());
      expect(round.phase, CoinchePhase.playing);
      expect(round.turn, Seat.south);
      expect(round.contract?.seat, Seat.south);
    });

    test(
      'un coéquipier du preneur ne peut pas contrer ; un adversaire le peut',
      () {
        var round = makeRound();
        round = placeBid(
          round,
          Seat.south,
          const ValueBid(80, CoincheSuit.deniers),
        );
        round = placeBid(round, Seat.west, const PassBid());
        // Nord est dans l'équipe du preneur : contre refusé.
        expect(
          identical(placeBid(round, Seat.north, const ContreBid()), round),
          isTrue,
        );
        // Est est dans l'autre équipe : contre accepté.
        final next = placeBid(round, Seat.north, const PassBid());
        final contred = placeBid(next, Seat.east, const ContreBid());
        expect(contred.contract?.multiplier, 2);
        expect(contred.turn, Seat.south);
      },
    );

    test('chooseBid passe avec une main sans force', () {
      final weak = [
        for (final r in [CoincheRank.seven, CoincheRank.eight])
          card(CoincheSuit.epees, r),
      ];
      final round = makeRound(hands: {Seat.south: weak});
      expect(chooseBid(round, Seat.south), isA<PassBid>());
    });
  });

  group('jeu de la carte', () {
    final playingContract = const Contract(
      seat: Seat.north,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );

    test('il faut fournir la couleur demandée', () {
      final south = [
        card(CoincheSuit.epees, CoincheRank.seven),
        card(CoincheSuit.batons, CoincheRank.ace),
        card(CoincheSuit.coupes, CoincheRank.eight),
      ];
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: playingContract,
        hands: {Seat.south: south},
        trick: [
          Play(seat: Seat.west, card: card(CoincheSuit.epees, CoincheRank.ten)),
        ],
      );
      expect(legalCards(round, Seat.south).map((c) => c.id).toList(), [
        'epees-7',
      ]);
    });

    test('sans la couleur, il faut couper avec un atout', () {
      final south = [
        card(CoincheSuit.coupes, CoincheRank.seven),
        card(CoincheSuit.batons, CoincheRank.ace),
      ];
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: playingContract,
        hands: {Seat.south: south},
        trick: [
          Play(seat: Seat.west, card: card(CoincheSuit.epees, CoincheRank.ace)),
        ],
      );
      expect(legalCards(round, Seat.south).map((c) => c.id).toList(), [
        'coupes-7',
      ]);
    });

    test('si le partenaire est maître, aucune obligation de couper', () {
      final south = [
        card(CoincheSuit.coupes, CoincheRank.seven),
        card(CoincheSuit.batons, CoincheRank.ace),
      ];
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: playingContract,
        hands: {Seat.south: south},
        trick: [
          Play(
            seat: Seat.west,
            card: card(CoincheSuit.epees, CoincheRank.seven),
          ),
          Play(
            seat: Seat.north,
            card: card(CoincheSuit.epees, CoincheRank.ace),
          ),
        ],
      );
      expect(legalCards(round, Seat.south).map((c) => c.id).toList(), [
        'coupes-7',
        'batons-A',
      ]);
    });

    test('à l\'atout, il faut monter si possible', () {
      final south = [
        card(CoincheSuit.coupes, CoincheRank.seven),
        card(CoincheSuit.coupes, CoincheRank.nine),
      ];
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: playingContract,
        hands: {Seat.south: south},
        trick: [
          Play(
            seat: Seat.west,
            card: card(CoincheSuit.coupes, CoincheRank.eight),
          ),
          Play(
            seat: Seat.east,
            card: card(CoincheSuit.coupes, CoincheRank.seven),
          ),
        ],
      );
      expect(legalCards(round, Seat.south).map((c) => c.id).toList(), [
        'coupes-9',
      ]);
    });

    test('roi et dame d\'atout dans la même main : belote pour l\'équipe', () {
      final south = [
        card(CoincheSuit.coupes, CoincheRank.roi),
        card(CoincheSuit.coupes, CoincheRank.dame),
        card(CoincheSuit.batons, CoincheRank.ace),
      ];
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: const Contract(
          seat: Seat.west,
          value: 80,
          mode: CoincheSuit.coupes,
          multiplier: 1,
        ),
        hands: {Seat.south: south},
      );
      final next = playCard(round, Seat.south, 'coupes-R');
      expect(next.belote, Team.ns);
      expect(next.turn, Seat.west);
      expect(next.hands[Seat.south], hasLength(2));
      // Un joueur hors tour ne peut pas jouer.
      expect(identical(playCard(round, Seat.west, 'coupes-R'), round), isTrue);
    });
  });

  group('score', () {
    test('capot : 250 points pour l\'attaque (dix de der compris)', () {
      final round = makeRound(
        phase: CoinchePhase.done,
        contract: const Contract(
          seat: Seat.south,
          value: 80,
          mode: CoincheSuit.deniers,
          multiplier: 1,
        ),
        tricksPlayed: handSize,
        tricksWon: {Team.ns: handSize, Team.ew: 0},
        lastWinner: Seat.south,
      );
      final result = scoreRound(round)!;
      expect(result.capot, isTrue);
      expect(result.made, isTrue);
      expect(result.points[Team.ns], capotPoints);
      expect(result.awarded[Team.ns], capotPoints + 80);
      expect(result.awarded[Team.ew], 0);
    });

    test(
      'chute contrée avec belote : la défense reçoit 162 + belote + valeur × 2',
      () {
        final round = makeRound(
          phase: CoinchePhase.done,
          contract: const Contract(
            seat: Seat.south,
            value: 100,
            mode: CoincheSuit.deniers,
            multiplier: 2,
          ),
          tricksPlayed: handSize,
          tricksWon: {Team.ns: 3, Team.ew: 5},
          pointsWon: {Team.ns: 40, Team.ew: 122},
          lastWinner: Seat.east,
          belote: Team.ew,
        );
        final result = scoreRound(round)!;
        expect(result.made, isFalse);
        expect(result.capot, isFalse);
        expect(result.awarded[Team.ew], totalCardPoints + belotePoints + 200);
        expect(result.awarded[Team.ns], 0);
      },
    );

    test('scoreRound renvoie null tant que la manche n\'est pas finie', () {
      final round = makeRound(
        phase: CoinchePhase.playing,
        contract: const Contract(
          seat: Seat.south,
          value: 80,
          mode: CoincheSuit.deniers,
          multiplier: 1,
        ),
      );
      expect(scoreRound(round), isNull);
    });

    test('applyRound ajoute les points et passe à la manche suivante', () {
      final match = newMatch(1000);
      final result = CoincheRoundResult(
        contract: const Contract(
          seat: Seat.south,
          value: 80,
          mode: CoincheSuit.deniers,
          multiplier: 1,
        ),
        made: true,
        capot: false,
        points: {Team.ns: 90, Team.ew: 72},
        awarded: {Team.ns: 170, Team.ew: 72},
      );
      final next = applyRound(match, result);
      expect(next.scores[Team.ns], 170);
      expect(next.scores[Team.ew], 72);
      expect(next.round, 2);
      expect(next.winner, isNull);
    });
  });

  group('sérialisation', () {
    test('RoundState : toJson puis fromJson redonne le même JSON', () {
      final round = dealRound(Seat.east, math.Random(7).nextDouble);
      final json = round.toJson();
      final decoded = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      expect(RoundState.fromJson(decoded).toJson(), equals(json));
    });
  });

  group('niveaux de l\'IA', () {
    final contract = const Contract(
      seat: Seat.north,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );
    // Le partenaire (nord) tient le pli avec l'as de bâton, sud doit jouer.
    final partnerWinning = [
      Play(seat: Seat.west, card: card(CoincheSuit.batons, CoincheRank.seven)),
      Play(seat: Seat.north, card: card(CoincheSuit.batons, CoincheRank.ace)),
      Play(seat: Seat.east, card: card(CoincheSuit.batons, CoincheRank.roi)),
    ];
    final south = [
      card(CoincheSuit.batons, CoincheRank.ten),
      card(CoincheSuit.batons, CoincheRank.nine),
    ];

    test('difficile donne la carte la plus chère à son partenaire', () {
      final round = makeRound(
        phase: CoinchePhase.playing,
        turn: Seat.south,
        contract: contract,
        hands: {Seat.south: south},
        trick: partnerWinning,
      );
      expect(
        chooseCard(round, Seat.south, false, null, CoincheAiLevel.difficile),
        card(CoincheSuit.batons, CoincheRank.ten).id,
      );
      expect(
        chooseCard(round, Seat.south, false, null, CoincheAiLevel.moyen),
        card(CoincheSuit.batons, CoincheRank.nine).id,
      );
    });

    test('facile passe une annonce que le moyen accepte', () {
      // Valet 20 + neuf 14 + dix 10 = 44 : entre le seuil moyen (36) et le seuil facile (46).
      final hand = [
        card(CoincheSuit.coupes, CoincheRank.valet),
        card(CoincheSuit.coupes, CoincheRank.nine),
        card(CoincheSuit.coupes, CoincheRank.ten),
      ];
      final round = makeRound(hands: {Seat.south: hand});
      expect(
        chooseBid(round, Seat.south, CoincheAiLevel.moyen),
        isA<ValueBid>(),
      );
      expect(
        chooseBid(round, Seat.south, CoincheAiLevel.facile),
        isA<PassBid>(),
      );
    });
  });
}
