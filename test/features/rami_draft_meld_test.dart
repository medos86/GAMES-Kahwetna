// Paquet en cours sur le tapis (#874) : les cartes se glissent une à une, le paquet est posé
// dès qu'il est valide, et défausser ou annuler rend les cartes à la main.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/rami.dart' as rules;

rules.RamiCard card(rules.RamiSuit suit, int rank, String id) =>
    rules.RamiCard(id: id, suit: suit, rank: rank);

/// Contrôleur en phase de pose, au tour du joueur, avec la main donnée.
RamiController controllerWith(List<rules.RamiCard> hand) {
  final base = rules.dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  final state = base.copyWith(
    phase: rules.RamiPhase.play,
    turn: 0,
    staged: const [],
    opened: [false, false, false, false],
    lastOpening: 0,
    firstTour: false,
    hands: [
      hand,
      for (final seat in [1, 2, 3]) base.hands[seat],
    ],
  );
  final c = RamiController(
    targetScore: 100,
    difficulty: rules.RamiAiLevel.facile,
    random: () => 0.0,
  );
  c.applySnapshot(state.toJson());
  return c;
}

void main() {
  final kings = [
    card(rules.RamiSuit.epees, 13, 'ks'),
    card(rules.RamiSuit.coupes, 13, 'kh'),
    card(rules.RamiSuit.batons, 13, 'kc'),
  ];
  final extra = card(rules.RamiSuit.deniers, 2, 'x');
  final filler = card(rules.RamiSuit.deniers, 9, 'f');

  test('deux cartes glissées sur le tapis restent en paquet en cours', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());

      expect(c.game.table, isEmpty);
      expect(c.draftIds, ['ks', 'kh']);
      expect([for (final card in c.draftCards) card.id], ['ks', 'kh']);
      expect(c.displayed.any((card) => card.id == 'ks'), isFalse);
      c.dispose();
    });
  });

  test('la troisième carte qui forme un paquet valide le pose', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());
      c.dropCard('kc', const RamiDropTable());

      expect(c.game.table.length, 1);
      expect(c.draftIds, isEmpty);
      c.dispose();
    });
  });

  test('une carte qui ne forme pas de paquet reste en cours', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());
      c.dropCard('x', const RamiDropTable());

      expect(c.game.table, isEmpty);
      expect(c.draftIds, ['ks', 'kh', 'x']);
      c.dispose();
    });
  });

  test('défausser rend les cartes du paquet en cours à la main', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());
      c.discardOne('x');

      expect(c.draftIds, isEmpty);
      expect(c.game.discard.last.id, 'x');
      expect(c.game.hands[0].any((card) => card.id == 'ks'), isTrue);
      expect(c.game.hands[0].any((card) => card.id == 'kh'), isTrue);
      c.dispose();
    });
  });

  test('retirer une carte du paquet la rend à la main', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());
      c.removeFromDraft('kh');

      expect(c.draftIds, ['ks']);
      expect(c.displayed.any((card) => card.id == 'kh'), isTrue);
      c.dispose();
    });
  });

  test('annuler vide le paquet en cours', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.dropCard('ks', const RamiDropTable());
      c.dropCard('kh', const RamiDropTable());
      c.cancel();

      expect(c.draftIds, isEmpty);
      expect(c.game.table, isEmpty);
      c.dispose();
    });
  });
}
