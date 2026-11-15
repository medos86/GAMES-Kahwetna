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
    final slots = {
      for (final color in LudoColor.values) color: ludoGoalSlot(color),
    };
    expect(slots.values.toSet().length, 4);
    for (final slot in slots.values) {
      expect(slot.x, inInclusiveRange(6, 9));
      expect(slot.y, inInclusiveRange(6, 9));
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
