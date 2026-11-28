// Placement de la chaîne autour de la première pierre (#930).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_chain_layout.dart';

bool _overlap(ChainSlot a, ChainSlot b) =>
    a.x < b.x + b.width &&
    b.x < a.x + a.width &&
    a.y < b.y + b.height &&
    b.y < a.y + a.height;

bool _touch(ChainSlot a, ChainSlot b) {
  final shareX = a.x < b.x + b.width && b.x < a.x + a.width;
  final shareY = a.y < b.y + b.height && b.y < a.y + a.height;
  final side = (a.x + a.width == b.x || b.x + b.width == a.x) &&
      a.y < b.y + b.height &&
      b.y < a.y + a.height;
  final stacked = (a.y + a.height == b.y || b.y + b.height == a.y) && shareX;
  return (side || stacked) && !(shareX && shareY);
}

void main() {
  test('#930 : pas de chevauchement, chaque pierre touche la précédente', () {
    for (final halfWidth in [6, 8]) {
      for (var count = 1; count <= 40; count++) {
        for (var open = 0; open < count; open++) {
          final slots = layoutChainAroundCenter(
            count: count,
            openIndex: open,
            halfWidth: halfWidth,
          );
          expect(slots.length, count);
          for (var i = 0; i < count; i++) {
            for (var j = i + 1; j < count; j++) {
              expect(
                _overlap(slots[i], slots[j]),
                isFalse,
                reason: 'chevauchement $i/$j (n=$count, open=$open)',
              );
            }
            if (i + 1 < count) {
              expect(
                _touch(slots[i], slots[i + 1]),
                isTrue,
                reason: 'pierres $i et ${i + 1} non reliées',
              );
            }
          }
        }
      }
    }
  });

  test('#930 : la première pierre est au centre, horizontale', () {
    final slots = layoutChainAroundCenter(count: 5, openIndex: 2, halfWidth: 6);
    expect(slots[2].x, -1);
    expect(slots[2].y, 0);
    expect(slots[2].vertical, isFalse);
  });

  test('#930 : tout reste dans le tapis, symétrique en largeur', () {
    for (final halfWidth in [6, 8]) {
      final slots = layoutChainAroundCenter(
        count: 60,
        openIndex: 30,
        halfWidth: halfWidth,
      );
      for (final s in slots) {
        expect(s.x >= -halfWidth && s.x + s.width <= halfWidth, isTrue);
      }
    }
  });

  test('#930 : le bras droit descend, le bras gauche monte', () {
    final slots = layoutChainAroundCenter(
      count: 25,
      openIndex: 12,
      halfWidth: 6,
    );
    expect(slots.last.y > 0, isTrue);
    expect(slots.first.y < 0, isTrue);
  });

  test('#1064 : le remplissage de largeur fait toucher le bord du tapis', () {
    const width = 400.0;
    for (final edge in [4, 6, 8]) {
      final scale = fullWidthScale(edge: edge, width: width, unit: 20);
      expect(edge * 20 * scale, closeTo(width / 2, 1e-9));
    }
  });

  test('#1064 : la chaîne reste dans le tapis', () {
    final slots = layoutChainAroundCenter(
      count: 30,
      openIndex: 0,
      halfWidth: 6,
    );
    for (final s in slots) {
      expect(s.x >= -6 && s.x + s.width <= 6, isTrue);
    }
    expect(slots.any((s) => s.vertical && s.x + s.width == 6), isTrue);
  });

  test('#1064 : la chaîne touche toujours le bord du tapis', () {
    const width = 960.0;
    const unit = 95.0;
    final fitted = layoutChainFitted(
      count: 40,
      openIndex: 20,
      width: width,
      height: 3000,
      unit: unit,
    );
    var maxX = 0;
    for (final s in fitted.slots) {
      maxX = maxX > s.x + s.width ? maxX : s.x + s.width;
    }
    expect(maxX * unit * fitted.scale, closeTo(width / 2, 1e-6));
  });

  test('#1069 : bord exact, virages au bord, par téléphone', () {
    const phones = [
      [360.0, 800.0],
      [390.0, 844.0],
      [412.0, 915.0],
      [430.0, 932.0],
      [768.0, 1024.0],
    ];
    for (final phone in phones) {
      final width = phone[0];
      final height = phone[1] * 0.6;
      final unit = width / 6;
      for (final count in [1, 5, 12, 25, 40, 60]) {
        for (final open in [0, count ~/ 2, count - 1]) {
          final fitted = layoutChainFitted(
            count: count,
            openIndex: open,
            width: width,
            height: height,
            unit: unit,
          );
          final cell = unit * fitted.scale;
          var maxX = 0;
          var minX = 0;
          for (final s in fitted.slots) {
            maxX = math.max(maxX, s.x + s.width);
            minX = math.min(minX, s.x);
          }
          if (count >= 12) {
            expect(
              math.max(maxX, -minX) * cell,
              closeTo(width / 2, 1e-6),
              reason: 'bord non aligné (w=$width, n=$count, open=$open)',
            );
          }
          final edge = (width / 2 / cell).round();
          for (final s in fitted.slots) {
            if (s.vertical) {
              expect(
                s.x + s.width == edge || s.x == -edge,
                isTrue,
                reason: 'virage hors bord (w=$width, n=$count, open=$open)',
              );
            }
          }
          expect(
            chainHalfHeight(slots: fitted.slots, unit: cell),
            lessThanOrEqualTo(height / 2 + 1e-6),
            reason: 'chaîne trop haute (w=$width, n=$count, open=$open)',
          );
        }
      }
    }
  });
}
