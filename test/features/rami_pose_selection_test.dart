// Sélection valide posée depuis la main (#940) : aperçu sur le tapis, pose par tap ou par glisser.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/rami.dart' as rules;

rules.RamiCard card(rules.RamiSuit suit, int rank, String id) =>
    rules.RamiCard(id: id, suit: suit, rank: rank);

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

  test('un groupe valide sélectionné active l\'aperçu sur le tapis', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.tap('ks');
      c.tap('kh');
      expect(c.canPoseSelection, isFalse);
      c.tap('kc');
      expect(c.canPoseSelection, isTrue);
      expect(c.game.table, isEmpty);
      c.dispose();
    });
  });

  test("un groupe valide reste en main tant qu'il n'est pas déposé (#972)", () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.tap('ks');
      c.tap('kh');
      c.tap('kc');
      expect(c.canPoseSelection, isTrue);
      expect(c.hand.map((card) => card.id), containsAll(['ks', 'kh', 'kc']));
      expect(c.game.table, isEmpty);
      c.dispose();
    });
  });

  test('un tap sur l\'aperçu pose le groupe et vide la sélection', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.tap('ks');
      c.tap('kh');
      c.tap('kc');
      c.pose();
      expect(c.game.table.length, 1);
      expect(c.hand.any((card) => card.id == 'ks'), isFalse);
      expect(c.selected, isEmpty);
      c.dispose();
    });
  });

  test('glisser une carte sélectionnée sur le tapis pose le groupe entier', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.tap('ks');
      c.tap('kh');
      c.tap('kc');
      c.dropCard('kh', const RamiDropTable());
      expect(c.game.table.length, 1);
      expect(c.draftIds, isEmpty);
      expect(c.selected, isEmpty);
      c.dispose();
    });
  });

  test('une sélection invalide ne forme pas d\'aperçu et ne se pose pas', () {
    fakeAsync((async) {
      final c = controllerWith([...kings, extra, filler]);
      c.tap('ks');
      c.tap('kh');
      c.pose();
      expect(c.canPoseSelection, isFalse);
      expect(c.game.table, isEmpty);
      expect(c.selected, ['ks', 'kh']);
      c.dispose();
    });
  });
}
