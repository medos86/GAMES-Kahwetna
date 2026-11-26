import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Calculs de la main et du tapis Rami (#270, #276).

void main() {
  test('écartement : rien sans dépôt dans la main', () {
    for (var i = 0; i < 5; i++) {
      expect(ramiGapOffset(i, -1, 100), 0);
    }
  });

  test('écartement : le dépôt écarte à partir de l\'emplacement', () {
    expect(ramiGapOffset(1, 2, 100), 0);
    expect(ramiGapOffset(2, 2, 100), closeTo(60, 1e-9));
    expect(ramiGapOffset(4, 2, 100), closeTo(60, 1e-9));
  });

  test('écartement : l\'ouverture reste visible même avec une main serrée', () {
    // Pas très serré (carte 100, pas 10) : l'écart doit tout de même dépasser le pas.
    expect(ramiGapOffset(2, 2, 100), greaterThan(10 * 2));
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

  test('tapis : la largeur calculée fait tenir tous les paquets', () {
    const area = 320.0;
    const height = 260.0;
    final sizes = [3, 3, 4, 3, 3, 4, 3];
    final w = ramiTableCardWidth(sizes, area, height, 80);
    if (w > 36) {
      final rows = ramiMeldRows(sizes, w, area)!;
      // Hauteur réelle : padding + bordure (12) par rangée, espace de 3 entre rangées.
      final used = rows * (w * 1.4 + 12) + (rows - 1) * 3;
      expect(used, lessThanOrEqualTo(height));
    }
  });
}
