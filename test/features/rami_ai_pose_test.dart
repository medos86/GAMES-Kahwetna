import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';
import 'package:kahwetne/game/rami.dart';

/// Issue #878 : les cartes posées par un adversaire sont détectées pour les animer une à une.
void main() {
  RamiCard c(String id) => RamiCard(id: id, suit: RamiSuit.epees, rank: 3);

  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0).copyWith(
    phase: RamiPhase.play,
    turn: 1,
    stock: [c('s1')],
    discard: [c('d1')],
    table: const [],
  );

  test('un paquet posé par l\'adversaire donne une carte par pose', () {
    final next = base.copyWith(
      table: [
        Meld(id: 'm1', cards: [c('a'), c('b'), c('c')], owner: 1),
      ],
    );
    expect(
      [for (final card in ramiNewTableCards(base, next)) card.id],
      ['a', 'b', 'c'],
    );
  });

  test('une carte ajoutée à un paquet existant est aussi animée', () {
    final before = base.copyWith(
      table: [
        Meld(id: 'm1', cards: [c('a'), c('b'), c('c')], owner: 1),
      ],
    );
    final next = before.copyWith(
      table: [
        Meld(id: 'm1', cards: [c('a'), c('b'), c('c'), c('x')], owner: 1),
      ],
    );
    expect(
      [for (final card in ramiNewTableCards(before, next)) card.id],
      ['x'],
    );
  });

  test('rien d\'animé pendant son propre tour', () {
    final mine = base.copyWith(turn: 0);
    final next = mine.copyWith(
      table: [
        Meld(id: 'm1', cards: [c('a')], owner: 0),
      ],
    );
    expect(ramiNewTableCards(mine, next), isEmpty);
  });

  test('aucun changement sur le tapis : aucune animation', () {
    final before = base.copyWith(
      table: [
        Meld(id: 'm1', cards: [c('a')], owner: 1),
      ],
    );
    expect(ramiNewTableCards(before, before), isEmpty);
  });
}
