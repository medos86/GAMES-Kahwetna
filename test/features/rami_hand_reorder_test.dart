// Réorganisation manuelle de la main du Rami (issue #68) : une carte lâchée devant ou après une autre
// change sa place, et l'ordre choisi survit au tri automatique et à l'arrivée de nouvelles cartes.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/rami.dart' as rules;

List<String> ids(RamiController c) => [for (final card in c.displayed) card.id];

void main() {
  test('une carte lâchée après la dernière prend la dernière place', () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      final before = ids(c);
      expect(before.length, greaterThan(2));

      c.dropCard(before.first, RamiDropHand(before.last, after: true));

      final after = ids(c);
      expect(after.last, before.first);
      expect(after.sublist(0, after.length - 1), before.sublist(1));
      c.dispose();
    });
  });

  test('une carte lâchée avant une autre prend sa place', () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      final before = ids(c);

      c.dropCard(before.last, RamiDropHand(before[1], after: false));

      final after = ids(c);
      expect(after[1], before.last);
      expect(after.length, before.length);
      expect(after.toSet(), before.toSet());
      c.dispose();
    });
  });

  test('lâcher une carte sur elle-même ne change rien', () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      final before = ids(c);
      c.dropCard(before.first, RamiDropHand(before.first, after: true));
      expect(ids(c), before);
      c.dispose();
    });
  });

  test('après un tri, l\'ordre choisi à la main reste valide (même cartes, pas de doublon)', () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      c.dropCard(c.displayed.first.id, RamiDropHand(c.displayed.last.id, after: true));
      c.sortBy(RamiSortMode.rank);
      final sorted = ids(c);
      expect(sorted.toSet().length, sorted.length);
      expect(sorted.toSet(), {for (final card in c.hand) card.id});
      c.dispose();
    });
  });
}
