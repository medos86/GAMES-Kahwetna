import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';

void main() {
  group('assignTableSlots', () {
    test('une carte retirée ne fait pas glisser les autres', () {
      final before = assignTableSlots({}, ['a', 'b', 'c']);
      expect(before, {'a': 0, 'b': 1, 'c': 2});
      final after = assignTableSlots(before, ['b', 'c']);
      expect(after, {'b': 1, 'c': 2});
    });

    test('une nouvelle carte prend le plus petit emplacement libre', () {
      final slots = assignTableSlots({'a': 0, 'b': 1, 'c': 2}, ['a', 'c']);
      final next = assignTableSlots(slots, ['a', 'c', 'd']);
      expect(next, {'a': 0, 'c': 2, 'd': 1});
    });

    test('les positions ne changent pas quand la table reste identique', () {
      final slots = assignTableSlots({}, ['x', 'y']);
      expect(assignTableSlots(slots, ['x', 'y']), slots);
    });
  });
}
