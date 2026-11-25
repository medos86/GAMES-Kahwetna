import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #943 : les paquets posés partent un par un, pas tous en même temps.
void main() {
  test('un seul paquet : ses cartes se suivent à 120 ms', () {
    expect(ramiPackDelays([3]), [
      Duration.zero,
      const Duration(milliseconds: 120),
      const Duration(milliseconds: 240),
    ]);
  });

  test('le paquet suivant ne part qu’après le précédent', () {
    final delays = ramiPackDelays([3, 2]);
    // 240 ms d'écart dans le premier paquet, puis la pause avant le second.
    expect(delays[3], const Duration(milliseconds: 640));
    expect(delays[4], const Duration(milliseconds: 760));
    expect(delays[3] > delays[2], isTrue);
  });

  test('les paquets vides et la liste vide ne produisent aucun délai', () {
    expect(ramiPackDelays(const []), isEmpty);
    expect(ramiPackDelays([0, 0]), isEmpty);
    expect(ramiPackDelays([0, 2]), [
      Duration.zero,
      const Duration(milliseconds: 120),
    ]);
  });

  test('chaque carte garde un délai au plus égal à la suivante', () {
    final delays = ramiPackDelays([4, 1, 3]);
    expect(delays.length, 8);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i] >= delays[i - 1], isTrue);
    }
  });
}
