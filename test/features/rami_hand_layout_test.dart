import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Calculs de la main et du tapis Rami (#270, #276).

void main() {
  test('écartement : rien sans dépôt dans la main', () {
    for (var i = 0; i < 5; i++) {
      expect(ramiGapOffset(i, -1, 30), 0);
    }
  });

  test('écartement : le dépôt écarte à partir de l\'emplacement', () {
    expect(ramiGapOffset(1, 2, 30), 0);
    expect(ramiGapOffset(2, 2, 30), closeTo(27, 1e-9));
    expect(ramiGapOffset(4, 2, 30), closeTo(27, 1e-9));
  });

  test('ordre de dessin : de gauche à droite', () {
    expect(ramiDrawOrder(3, null), [0, 1, 2]);
    expect(ramiDrawOrder(0, null), isEmpty);
  });

  test('ordre de dessin : la carte déplacée passe en dernier', () {
    expect(ramiDrawOrder(4, 1), [0, 2, 3, 1]);
  });

  test('tapis : sans paquet, largeur maximale', () {
    expect(ramiTableCardWidth([], 300, 200, 80), 80);
  });

  test('tapis : un seul paquet court garde la largeur maximale', () {
    expect(ramiTableCardWidth([3], 300, 200, 80), 80);
  });

  test('tapis : les paquets se rangent sur une rangée s\'ils tiennent', () {
    const w = 60.0;
    expect(ramiMeldRows([3, 3], w, 400), 1);
    expect(ramiMeldRows([3, 3, 3, 3], w, 200), greaterThan(1));
  });

  test('tapis : trop de paquets pour la zone, largeur minimale', () {
    final sizes = List<int>.filled(12, 4);
    expect(ramiTableCardWidth(sizes, 60, 40, 80), 36);
  });

  test('tapis : plus de paquets donnent des cartes plus petites', () {
    const area = 320.0;
    const height = 260.0;
    final few = ramiTableCardWidth([3, 3, 4], area, height, 80);
    final many = ramiTableCardWidth(
      [3, 3, 4, 3, 3, 4, 3, 3, 4, 3],
      area,
      height,
      80,
    );
    expect(many, lessThanOrEqualTo(few));
    expect(many, greaterThanOrEqualTo(36));
  });

  test('main : écart avec le tapis resserré (#319)', () {
    expect(ramiHandGap, greaterThan(0));
    // Écart total = SizedBox + padding haut du footer : doit rester sous 6 px (avant : 12 px).
    expect(ramiHandGap * 2, lessThan(6));
    // L'espace gagné correspond à l'ancien écart (12 px) moins le nouveau (4 px).
    expect(ramiHandGapSaved, 12 - ramiHandGap * 2);
  });

  test('tapis : la largeur calculée fait tenir tous les paquets', () {
    const area = 320.0;
    const height = 260.0;
    final sizes = [3, 3, 4, 3, 3, 4, 3];
    final w = ramiTableCardWidth(sizes, area, height, 80);
    if (w > 36) {
      final rows = ramiMeldRows(sizes, w, area)!;
      final used = rows * (w * 1.4 + 10) + (rows - 1) * 6;
      expect(used, lessThanOrEqualTo(height));
    }
  });
}
