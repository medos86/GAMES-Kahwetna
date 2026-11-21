// Pions multiples sur une même case (#681) : aucun nombre de pions ne doit
// faire planter le plateau.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  List<Token> stacked(int count) => [
        for (var i = 0; i < count; i++)
          Token(id: 'red-$i', color: LudoColor.red, progress: 1),
      ];

  for (final count in [2, 3, 4, 5, 9, 16]) {
    test('#681 : $count pions sur une case, positions distinctes', () {
      final placed = layoutTokens(stacked(count));
      expect(placed, hasLength(count));
      final spots = {
        for (final p in placed)
          '${p.x.toStringAsFixed(4)}:${p.y.toStringAsFixed(4)}',
      };
      expect(spots, hasLength(count));
    });
  }

  test('#681 : décalage au-delà de 4 pions reste dans la case', () {
    for (var i = 0; i < 16; i++) {
      final offset = ludoStackOffset(i, 16);
      expect(offset[0].abs(), lessThan(0.5));
      expect(offset[1].abs(), lessThan(0.5));
    }
  });
}
