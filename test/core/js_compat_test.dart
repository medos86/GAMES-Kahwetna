import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/utils/js_compat.dart';

void main() {
  group('slice (Array.prototype.slice)', () {
    final items = [0, 1, 2, 3, 4];

    test('sans borne : copie complète', () {
      final copy = slice(items);
      expect(copy, [0, 1, 2, 3, 4]);
      expect(identical(copy, items), isFalse);
    });

    test('start et end positifs', () {
      expect(slice(items, 1, 3), [1, 2]);
      expect(slice(items, 2), [2, 3, 4]);
    });

    test('indices négatifs comptés depuis la fin', () {
      expect(slice(items, -2), [3, 4]);
      expect(slice(items, 0, -1), [0, 1, 2, 3]);
      expect(slice(items, -3, -1), [2, 3]);
    });

    test('bornes clampées, sans exception', () {
      expect(slice(items, -100), [0, 1, 2, 3, 4]);
      expect(slice(items, 3, 100), [3, 4]);
      expect(slice(items, 10), isEmpty);
      expect(slice(items, -100, -50), isEmpty);
    });

    test('start >= end donne une liste vide', () {
      expect(slice(items, 3, 3), isEmpty);
      expect(slice(items, 4, 2), isEmpty);
      expect(slice(items, -1, -3), isEmpty);
    });

    test('liste vide', () {
      expect(slice(<int>[], 0, 5), isEmpty);
      expect(slice(<int>[], -1), isEmpty);
    });

    test('ne modifie pas la liste d\'origine', () {
      slice(items, 1, 3);
      expect(items, [0, 1, 2, 3, 4]);
    });
  });

  group('sortedStable', () {
    test('trie par la comparaison', () {
      expect(sortedStable([3, 1, 2], (a, b) => a.compareTo(b)), [1, 2, 3]);
    });

    test('stable : les égaux gardent leur ordre d\'origine', () {
      final items = [
        (key: 1, name: 'a'),
        (key: 0, name: 'b'),
        (key: 1, name: 'c'),
        (key: 0, name: 'd'),
        (key: 1, name: 'e'),
      ];
      final sorted = sortedStable(items, (x, y) => x.key.compareTo(y.key));
      expect(sorted.map((e) => e.name).toList(), ['b', 'd', 'a', 'c', 'e']);
    });

    test('stable sur une grande liste (au-delà du seuil du tri par insertion)', () {
      final items = [for (var i = 0; i < 500; i++) (key: i % 3, id: i)];
      final sorted = sortedStable(items, (x, y) => x.key.compareTo(y.key));
      for (var i = 1; i < sorted.length; i++) {
        final prev = sorted[i - 1];
        final cur = sorted[i];
        expect(prev.key <= cur.key, isTrue);
        if (prev.key == cur.key) expect(prev.id < cur.id, isTrue);
      }
    });

    test('ne modifie pas la liste d\'origine', () {
      final items = [3, 1, 2];
      sortedStable(items, (a, b) => a.compareTo(b));
      expect(items, [3, 1, 2]);
    });

    test('liste vide', () {
      expect(sortedStable(<int>[], (a, b) => a.compareTo(b)), isEmpty);
    });
  });

  group('shuffled (Fisher-Yates)', () {
    test('est une permutation de la liste d\'origine', () {
      var seed = 0.0;
      double random() {
        seed = (seed + 0.37) % 1;
        return seed;
      }

      final items = [for (var i = 0; i < 20; i++) i];
      final result = shuffled(items, random);
      expect(result.length, items.length);
      expect([...result]..sort(), items);
    });

    test('ne modifie pas la liste d\'origine', () {
      final items = [1, 2, 3, 4];
      shuffled(items, () => 0.5);
      expect(items, [1, 2, 3, 4]);
    });

    test('suite fixée : même résultat que le source (j = floor(r * (i + 1)))', () {
      // random() = 0 : j = 0 à chaque étape.
      // [a,b,c,d] : i=3 échange 3<->0 -> [d,b,c,a] ; i=2 échange 2<->0 -> [c,b,d,a] ;
      // i=1 échange 1<->0 -> [b,c,d,a].
      expect(shuffled(['a', 'b', 'c', 'd'], () => 0), ['b', 'c', 'd', 'a']);
    });

    test('random() proche de 1 : j = i, aucun échange', () {
      expect(shuffled([1, 2, 3, 4], () => 0.999999), [1, 2, 3, 4]);
    });

    test('listes de taille 0 et 1', () {
      expect(shuffled(<int>[], () => 0.5), isEmpty);
      expect(shuffled([7], () => 0.5), [7]);
    });
  });
}
