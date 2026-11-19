// Issue #537 : chaque paquet garde le siège de son créateur (pour l'afficher sur le tapis).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_screen.dart' show ramiOwnerName;
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

RamiState playing({required int turn, required List<RamiCard> hand}) {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  final filler = [c(RamiSuit.coupes, 13), c(RamiSuit.batons, 13)];
  return base.copyWith(
    phase: RamiPhase.play,
    turn: turn,
    hands: [
      for (var i = 0; i < 4; i++) i == turn ? hand : filler,
    ],
    table: const [],
    opened: [true, true, true, true],
    staged: const [],
    takenId: null,
    firstTour: false,
  );
}

void main() {
  group('Rami : propriétaire des paquets (#537)', () {
    test('un paquet posé garde le siège de son créateur', () {
      final state = playing(
        turn: 2,
        hand: [
          c(RamiSuit.epees, 7),
          c(RamiSuit.epees, 8),
          c(RamiSuit.epees, 9),
          c(RamiSuit.coupes, 2),
        ],
      );

      final next = poseMeld(state, ['epees-7', 'epees-8', 'epees-9']);

      expect(next.table, hasLength(1));
      expect(next.table.single.owner, 2);
    });

    test('poser une carte sur le paquet d\'un autre garde le créateur', () {
      final base = playing(
        turn: 0,
        hand: [c(RamiSuit.epees, 7), c(RamiSuit.coupes, 2)],
      );
      final withMeld = base.copyWith(
        table: [
          Meld(
            id: 'meld-1',
            owner: 2,
            cards: [
              c(RamiSuit.coupes, 3),
              c(RamiSuit.coupes, 4),
              c(RamiSuit.coupes, 5),
            ],
          ),
        ],
      );
      final hand = [c(RamiSuit.coupes, 6), c(RamiSuit.coupes, 2)];
      final state = withMeld.copyWith(
        turn: 1,
        hands: [
          for (var i = 0; i < 4; i++) i == 1 ? hand : withMeld.hands[i],
        ],
      );

      final next = layOff(state, 'coupes-6', 'meld-1');

      expect(next.table.single.cards, hasLength(4));
      expect(next.table.single.owner, 2);
    });

    test('le propriétaire survit à un aller-retour de sauvegarde', () {
      const meld = Meld(
        id: 'meld-1',
        owner: 3,
        cards: [],
      );
      expect(Meld.fromJson(meld.toJson()).owner, 3);
    });

    test('une ancienne sauvegarde sans propriétaire donne -1', () {
      final meld = Meld.fromJson({
        'id': 'meld-1',
        'cards': <Map<String, dynamic>>[],
      });
      expect(meld.owner, -1);
    });

    test('nom affiché : Toi, Ali, Karim, Sami ; rien si siège inconnu', () {
      expect(ramiOwnerName(0), 'Toi');
      expect(ramiOwnerName(1), 'Ali');
      expect(ramiOwnerName(2), 'Karim');
      expect(ramiOwnerName(3), 'Sami');
      expect(ramiOwnerName(-1), isNull);
      expect(ramiOwnerName(4), isNull);
    });
  });
}
