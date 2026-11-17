import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Issue #453 : le tapis range les paquets pour remplir les trous du haut et rester sans défilement.
// Largeur d'un paquet avec une carte de 40 px : 40 + 16 × (n - 1) + 6.

double _width(int count, double cardWidth) =>
    cardWidth + cardWidth * 0.4 * (count - 1) + 6;

void main() {
  test('un petit paquet remplit le trou laissé en haut', () {
    // Deux gros paquets ne tiennent pas côte à côte : le second passe à la rangée 2,
    // puis le petit paquet revient remplir la place libre de la rangée 1.
    expect(ramiPackMelds([6, 6, 1], 40, 200), [0, 1, 0]);
    expect(ramiMeldRows([6, 6, 1], 40, 200), 2);
  });

  test('un paquet qui ne tient pas seul renvoie null', () {
    expect(ramiPackMelds([20], 40, 200), isNull);
    expect(ramiMeldRows([20], 40, 200), isNull);
  });

  test('tapis vide : aucune rangée', () {
    expect(ramiPackMelds(const [], 40, 200), isEmpty);
    expect(ramiMeldRows(const [], 40, 200), 0);
  });

  test('l\'ordre d\'affichage regroupe chaque rangée et garde l\'ordre interne', () {
    expect(ramiPackedOrder([0, 1, 0]), [0, 2, 1]);
    expect(ramiPackedOrder([2, 0, 1, 0]), [1, 3, 2, 0]);
    expect(ramiPackedOrder(const []), isEmpty);
  });

  test('aucune rangée ne dépasse la largeur disponible', () {
    final random = Random(453);
    for (var trial = 0; trial < 200; trial++) {
      final sizes = [for (var i = 0; i < 8; i++) 1 + random.nextInt(6)];
      const cardWidth = 40.0;
      const area = 220.0;
      final rowOf = ramiPackMelds(sizes, cardWidth, area);
      if (rowOf == null) continue;
      final rowUsed = <int, double>{};
      for (var i = 0; i < sizes.length; i++) {
        final w = _width(sizes[i], cardWidth);
        rowUsed.update(rowOf[i], (u) => u + 3 + w, ifAbsent: () => w);
      }
      for (final used in rowUsed.values) {
        expect(used, lessThanOrEqualTo(area));
      }
    }
  });

  test('le rangement ne prend jamais plus de rangées que le remplissage séquentiel', () {
    final random = Random(7);
    for (var trial = 0; trial < 200; trial++) {
      final sizes = [for (var i = 0; i < 10; i++) 1 + random.nextInt(5)];
      const cardWidth = 36.0;
      const area = 180.0;
      final packed = ramiMeldRows(sizes, cardWidth, area);
      if (packed == null) continue;
      // Remplissage séquentiel de référence (une seule rangée ouverte à la fois).
      var sequential = 0;
      var used = 0.0;
      for (final count in sizes) {
        final w = _width(count, cardWidth);
        if (sequential == 0) {
          sequential = 1;
          used = w;
        } else if (used + 3 + w <= area) {
          used += 3 + w;
        } else {
          sequential++;
          used = w;
        }
      }
      expect(packed, lessThanOrEqualTo(sequential));
    }
  });
}
