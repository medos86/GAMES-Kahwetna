import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

// Saut case par case et arrivée propre à chaque couleur (#378).
void main() {
  test('le pion passe par chaque case intermédiaire', () {
    final points = ludoHopWaypoints(LudoColor.red, 1, 4);
    // Progressions 2 et 3 : deux cases intermédiaires, la 4 est la destination.
    expect(points.length, 2);
    final c2 = cellOf(const Token(id: '', color: LudoColor.red, progress: 2))!;
    expect(points.first.x, c2.col + 0.5);
    expect(points.first.y, c2.row + 0.5);
  });

  test('un déplacement d une seule case n a pas de point intermédiaire', () {
    expect(ludoHopWaypoints(LudoColor.red, 5, 6), isEmpty);
  });

  test('chaque couleur a son emplacement d arrivée, dans le centre', () {
    for (final color in LudoColor.values) {
      final slot = ludoGoalSlot(color);
      expect(slot.x, inInclusiveRange(6, 9));
      expect(slot.y, inInclusiveRange(6, 9));
    }
  });

  test('les 4 pions arrivés partent du point central (#980)', () {
    for (final color in LudoColor.values) {
      final first = ludoGoalSlot(color, 0);
      expect(first.x, ludoGoalCentre);
      expect(first.y, ludoGoalCentre);
    }
  });

  test('les 3 autres pions sont alignés, espacés d un pion (#980)', () {
    for (final color in LudoColor.values) {
      final slots = [for (var i = 0; i < 4; i++) ludoGoalSlot(color, i)];
      for (var i = 1; i < 4; i++) {
        final onAxisX = slots[i].x == ludoGoalCentre;
        final onAxisY = slots[i].y == ludoGoalCentre;
        expect(onAxisX || onAxisY, isTrue, reason: '${color.name} $i');
        final dx = slots[i].x - slots[i - 1].x;
        final dy = slots[i].y - slots[i - 1].y;
        final d = math.sqrt(dx * dx + dy * dy);
        expect(d, closeTo(0.5, 1e-9), reason: '${color.name} $i');
      }
    }
  });

  test('les pions arrivés d une couleur ne se chevauchent pas (#859)', () {
    for (final color in LudoColor.values) {
      final slots = [for (var i = 1; i < 4; i++) ludoGoalSlot(color, i)];
      for (var a = 0; a < slots.length; a++) {
        for (var b = a + 1; b < slots.length; b++) {
          final d = math.sqrt(
            math.pow(slots[a].x - slots[b].x, 2) +
                math.pow(slots[a].y - slots[b].y, 2),
          );
          expect(d, greaterThanOrEqualTo(0.5), reason: '${color.name} $a/$b');
        }
      }
    }
  });

  test('les 4 couleurs ont la même figure, tournée de 90 degrés (#859)', () {
    List<double> rel(LudoColor color) => [
          for (var i = 0; i < 4; i++) ...[
            ludoGoalSlot(color, i).x - ludoGoalCentre,
            ludoGoalSlot(color, i).y - ludoGoalCentre,
          ],
        ];
    final red = rel(LudoColor.red);
    for (var i = 0; i < 4; i++) {
      final dx = red[2 * i];
      final dy = red[2 * i + 1];
      // Rotation de 90 degrés : (dx, dy) devient (-dy, dx) pour le vert, puis deux fois de suite.
      final green = rel(LudoColor.green);
      expect(green[2 * i], closeTo(-dy, 1e-9));
      expect(green[2 * i + 1], closeTo(dx, 1e-9));
      final yellow = rel(LudoColor.yellow);
      expect(yellow[2 * i], closeTo(-dx, 1e-9));
      expect(yellow[2 * i + 1], closeTo(-dy, 1e-9));
      final blue = rel(LudoColor.blue);
      expect(blue[2 * i], closeTo(dy, 1e-9));
      expect(blue[2 * i + 1], closeTo(-dx, 1e-9));
    }
  });

  test('un pion arrivé se place à l emplacement de sa couleur', () {
    final tokens = [
      for (final color in LudoColor.values)
        Token(id: '${color.name}-0', color: color, progress: ludoFinish),
    ];
    final placed = layoutTokens(tokens);
    for (final p in placed) {
      final slot = ludoGoalSlot(p.token.color);
      expect(p.x, slot.x);
      expect(p.y, slot.y);
    }
  });
}
