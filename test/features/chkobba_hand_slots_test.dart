import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/game/chkobba.dart';

ChkobbaCard _card(String id) =>
    ChkobbaCard(suit: ChkobbaSuit.values.first, rank: 1, id: id);

// Issue #494 : jouer une carte ne fait pas changer de place les autres.
void main() {
  group('handLayout', () {
    test('une carte jouée laisse un vide, les autres gardent leur place', () {
      final cards = [_card('a'), _card('b'), _card('c')];
      final slots = assignTableSlots({}, [for (final c in cards) c.id]);
      expect(handLayout(slots, cards).map((c) => c?.id), ['a', 'b', 'c']);

      // On joue « a » (première carte) : « b » et « c » restent en place.
      final rest = [_card('b'), _card('c')];
      final after = assignTableSlots(slots, [for (final c in rest) c.id]);
      expect(handLayout(after, rest).map((c) => c?.id), [null, 'b', 'c']);
    });

    test('une carte piochée prend l\'emplacement libre', () {
      final before = [_card('b'), _card('c')];
      final slots = assignTableSlots({}, ['a', 'b', 'c']);
      final slotsAfterPlay =
          assignTableSlots(slots, [for (final c in before) c.id]);
      final next = [_card('d'), _card('b'), _card('c')];
      final nextSlots =
          assignTableSlots(slotsAfterPlay, [for (final c in next) c.id]);
      expect(handLayout(nextSlots, next).map((c) => c?.id), ['d', 'b', 'c']);
    });

    test('une main vide donne trois emplacements vides', () {
      expect(handLayout({}, const []), [null, null, null]);
    });
  });
}
