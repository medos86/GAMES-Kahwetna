import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_table_layout.dart';

void main() {
  group('chkobbaCellOffset', () {
    test('les deux premières cartes encadrent le centre', () {
      expect(chkobbaCellOffset(0, 4), const Offset(-0.5, 0));
      expect(chkobbaCellOffset(1, 4), const Offset(0.5, 0));
      expect(chkobbaCellOffset(2, 4), const Offset(-1.5, 0));
      expect(chkobbaCellOffset(3, 4), const Offset(1.5, 0));
    });

    test('chaque emplacement a une position unique', () {
      for (final columns in [4, 6]) {
        final seen = <Offset>{
          for (var i = 0; i < 60; i++) chkobbaCellOffset(i, columns),
        };
        expect(seen.length, 60);
      }
    });

    test('position stable quand une carte part', () {
      // Retirer une carte ne fait pas glisser les autres : même index, même place.
      expect(chkobbaCellOffset(5, 6), chkobbaCellOffset(5, 6));
      expect(chkobbaCellOffset(7, 4), chkobbaCellOffset(7, 4));
    });
  });

  group('chkobbaHandCardHeight', () {
    test('main plus grande sur écran moyen', () {
      expect(chkobbaHandCardHeight(700), closeTo(105, 0.5));
    });

    test('bornée sur petit et grand écran', () {
      expect(chkobbaHandCardHeight(300), 64);
      expect(chkobbaHandCardHeight(1200), 120);
    });
  });
}
