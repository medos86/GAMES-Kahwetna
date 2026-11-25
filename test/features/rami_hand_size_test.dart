import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #314 : les cartes de la main du joueur sont plus grandes qu'avant (1,35).
void main() {
  test('cartes de la main agrandies', () {
    expect(ramiHandCardScale, greaterThan(1.35));
  });

  // #896 : la taille de carte reste fixe, seul le chevauchement varie.
  group('ramiHandStep (#896)', () {
    test('une seule carte : pas nul', () {
      expect(ramiHandStep(1, 100, 500), 0);
      expect(ramiHandStep(0, 100, 500), 0);
    });

    test('peu de cartes : pas naturel de 60 %', () {
      expect(ramiHandStep(3, 100, 500), closeTo(60, 1e-9));
    });

    test('main qui s\'allonge : pas resserré pour tenir sur la largeur', () {
      // (300 - 100) / 4 = 50 < 60
      expect(ramiHandStep(5, 100, 300), closeTo(50, 1e-9));
    });

    test('main très longue : pas resserré pour tenir (#922)', () {
      // (500 - 100) / 19 : la main tient exactement sur la largeur.
      expect(ramiHandStep(20, 100, 500), closeTo(400 / 19, 1e-9));
    });

    test('le pas est proportionnel à la largeur de carte demandée', () {
      // Au pas naturel (60 %), doubler la carte double le pas : aucune réduction cachée.
      expect(
        ramiHandStep(3, 100, 900),
        closeTo(ramiHandStep(3, 50, 900) * 2, 1e-9),
      );
    });
  });
}
