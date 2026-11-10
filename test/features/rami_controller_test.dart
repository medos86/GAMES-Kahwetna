// Tests du contrôleur du Rami : tri de la main, tour de l'IA après son délai, coups refusés, dispose().
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/rami.dart' as rules;

void main() {
  test('tri par couleur puis par valeur, jokers à la fin', () {
    const hand = [
      rules.RamiCard(id: 'e7', suit: rules.RamiSuit.epees, rank: 7),
      rules.RamiCard(id: 'joker', suit: null, rank: 0),
      rules.RamiCard(id: 'd12', suit: rules.RamiSuit.deniers, rank: 12),
      rules.RamiCard(id: 'd2', suit: rules.RamiSuit.deniers, rank: 2),
    ];
    expect(
      [for (final card in sortRamiHand(hand, RamiSortMode.suit)) card.id],
      ['d2', 'd12', 'e7', 'joker'],
    );
    expect(
      [for (final card in sortRamiHand(hand, RamiSortMode.rank)) card.id],
      ['d2', 'e7', 'd12', 'joker'],
    );
  });

  test("le tour de l'IA arrive 550 ms après la défausse du joueur", () {
    fakeAsync((async) {
      // Tirage constant 0.0 : l'IA prend la défausse au premier tour.
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      expect(c.canDraw, isTrue);
      c.drawFromStock();
      expect(c.game.phase, rules.RamiPhase.play);

      c.discardOne(c.hand.first.id);
      expect(c.game.turn, 1);

      async.elapse(const Duration(milliseconds: 549));
      expect(c.game.phase, rules.RamiPhase.draw);

      async.elapse(const Duration(milliseconds: 1));
      expect(c.game.phase, rules.RamiPhase.play);
      c.dispose();
    });
  });

  test("dispose annule le minuteur de l'IA", () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.moyen,
        random: () => 0.0,
      );
      c.drawFromStock();
      c.discardOne(c.hand.first.id);
      expect(async.pendingTimers, isNotEmpty);
      c.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('un coup refusé prévient sans changer la partie', () {
    final messages = <String>[];
    final c = RamiController(
      targetScore: 100,
      difficulty: rules.RamiAiLevel.facile,
      random: () => 0.0,
      onMessage: messages.add,
    );
    final before = c.game;
    c.commit(); // pas encore de pioche : l'ouverture est refusée
    expect(identical(c.game, before), isTrue);
    expect(messages, ['Il faut au moins 51 points pour ouvrir']);
    c.dispose();
  });

  test('la carte piochée arrive à la fin de la main', () {
    final c = RamiController(
      targetScore: 100,
      difficulty: rules.RamiAiLevel.facile,
      random: () => 0.0,
    );
    final before = [for (final card in c.displayed) card.id];
    c.drawFromStock();
    final after = [for (final card in c.displayed) card.id];
    expect(after.length, before.length + 1);
    expect(after.sublist(0, before.length), before);
    c.dispose();
  });
}
