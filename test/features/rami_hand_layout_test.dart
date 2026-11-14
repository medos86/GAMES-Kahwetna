import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Éventail et écartement de la main Rami (#270).

void main() {
  test('une seule carte ou aucune : pas d\'inclinaison', () {
    expect(ramiFanAngle(0, 0), 0);
    expect(ramiFanAngle(0, 1), 0);
  });

  test('l\'éventail est symétrique et la carte du centre est droite', () {
    const count = 7;
    expect(ramiFanAngle(3, count), 0);
    for (var i = 0; i < count; i++) {
      expect(
        ramiFanAngle(i, count),
        closeTo(-ramiFanAngle(count - 1 - i, count), 1e-9),
      );
    }
    expect(ramiFanAngle(0, count), lessThan(0));
    expect(ramiFanAngle(count - 1, count), greaterThan(0));
  });

  test('l\'inclinaison reste modérée même avec une main pleine', () {
    for (var i = 0; i < 13; i++) {
      expect(ramiFanAngle(i, 13).abs(), lessThanOrEqualTo(0.25));
    }
  });

  test('sans dépôt dans la main, aucun écartement', () {
    for (var i = 0; i < 5; i++) {
      expect(ramiGapOffset(i, -1, 30), 0);
    }
  });

  test('le dépôt écarte les cartes à partir de l\'emplacement', () {
    expect(ramiGapOffset(1, 2, 30), 0);
    expect(ramiGapOffset(2, 2, 30), closeTo(27, 1e-9));
    expect(ramiGapOffset(4, 2, 30), closeTo(27, 1e-9));
  });
}
