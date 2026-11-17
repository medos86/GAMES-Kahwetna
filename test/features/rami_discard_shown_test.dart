import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_discard_shown.dart';
import 'package:kahwetne/game/rami.dart';

// Le tas de défausse ne disparaît pas pendant le vol d'une carte (#346).
void main() {
  const a = RamiCard(id: 'a', suit: null, rank: 1);
  const b = RamiCard(id: 'b', suit: null, rank: 2);

  test('défausse vide : rien à afficher', () {
    expect(ramiDiscardShown([], {}), isNull);
  });

  test('pas de vol en cours : la carte du dessus', () {
    expect(ramiDiscardShown([a, b], {}), b);
  });

  test('carte du dessus en vol : la carte précédente reste visible', () {
    // Joueur ou adversaire : même règle, la carte qui arrive est landing.
    expect(ramiDiscardShown([a, b], {'b'}), a);
  });

  test('première carte en vol : le tas reste vide jusqu’à l’arrivée', () {
    expect(ramiDiscardShown([a], {'a'}), isNull);
  });

  test('vol d’une autre carte : la carte du dessus est affichée', () {
    expect(ramiDiscardShown([a, b], {'a'}), b);
  });
}
