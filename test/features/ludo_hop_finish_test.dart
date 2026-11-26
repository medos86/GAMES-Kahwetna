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

  test('chaque emplacement d arrivée reste dans la zone centrale', () {
    for (final color in LudoColor.values) {
      for (var i = 0; i < 4; i++) {
        final slot = ludoGoalSlot(color, i);
        expect(slot.x, inInclusiveRange(5, 10));
        expect(slot.y, inInclusiveRange(5, 10));
      }
    }
  });

  test('les emplacements forment une grille 2×2 dans le triangle (#996)', () {
    for (final color in LudoColor.values) {
      for (var i = 0; i < 4; i++) {
        final slot = ludoGoalSlot(color, i);
        final dx = slot.x - ludoGoalCentre;
        final dy = slot.y - ludoGoalCentre;
        final d = math.sqrt(dx * dx + dy * dy);
        expect(d, inInclusiveRange(0.6, 1.4), reason: '${color.name} $i');
      }
    }
    for (var i = 0; i < 4; i++) {
      final slot = ludoGoalSlot(LudoColor.red, i);
      expect(slot.x, lessThan(ludoGoalCentre));
      expect((slot.y - ludoGoalCentre).abs(),
          lessThanOrEqualTo((slot.x - ludoGoalCentre).abs()));
    }
  });

  test('les pions arrivés des 4 couleurs ne se chevauchent pas (#996)', () {
    final all = [
      for (final color in LudoColor.values)
        for (var i = 0; i < 4; i++) ludoGoalSlot(color, i),
    ];
    for (var a = 0; a < all.length; a++) {
      for (var b = a + 1; b < all.length; b++) {
        final dx = all[a].x - all[b].x;
        final dy = all[a].y - all[b].y;
        final d = math.sqrt(dx * dx + dy * dy);
        expect(d, greaterThanOrEqualTo(0.5), reason: '$a/$b');
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

  test('le premier arrivé prend le premier emplacement, même ordre pour toutes les couleurs (#996)', () {
    for (final color in LudoColor.values) {
      final tokens = [
        Token(id: '${color.name}-0', color: color, progress: ludoFinish, arrival: 2),
        Token(id: '${color.name}-1', color: color, progress: ludoFinish, arrival: 1),
      ];
      final placed = {for (final p in layoutTokens(tokens)) p.token.id: p};
      final first = ludoGoalSlot(color, 0);
      final second = ludoGoalSlot(color, 1);
      expect(placed['${color.name}-1']!.x, first.x, reason: color.name);
      expect(placed['${color.name}-1']!.y, first.y, reason: color.name);
      expect(placed['${color.name}-0']!.x, second.x, reason: color.name);
      expect(placed['${color.name}-0']!.y, second.y, reason: color.name);
    }
  });
}
