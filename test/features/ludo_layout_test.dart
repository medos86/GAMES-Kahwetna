// Tests de placement des pions (layoutTokens) : base, case simple et pile de deux pions.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test(
    "le pion est plus grand qu'avant (#595) : 0,9 case seul, 0,52 en pile",
    () {
      expect(ludoTokenSize, 0.9);
      expect(ludoStackSize, 0.52);
    },
  );

  test('un pion en base se place sur le premier emplacement de sa maison', () {
    final placed = layoutTokens(newLudoGame().tokens);
    final red0 = placed.firstWhere((p) => p.token.id == 'red-0');
    expect(red0.x, 1.5);
    expect(red0.y, 1.5);
    expect(red0.size, ludoTokenSize);
  });

  test('un pion seul sur une case est centré et de taille normale', () {
    final state = newLudoGame().copyWith(
      tokens: [
        for (final t in newLudoGame().tokens)
          t.id == 'red-0' ? t.copyWith(progress: 1) : t,
      ],
    );
    final placed =
        layoutTokens(state.tokens).firstWhere((p) => p.token.id == 'red-0');
    final cell = ludoTrack[ludoStartIndex(LudoColor.red)];
    expect(placed.x, cell.col + 0.5);
    expect(placed.y, cell.row + 0.5);
    expect(placed.size, ludoTokenSize);
  });

  test('#780 : deux pions sur le plateau, taille normale, décalage', () {
    // Rouge progression 40 et bleu progression 1 tombent sur la même case (index 40).
    final base = newLudoGame();
    final tokens = [
      for (final t in base.tokens)
        if (t.id == 'red-0')
          t.copyWith(progress: 40)
        else if (t.id == 'blue-0')
          t.copyWith(progress: 1)
        else
          t,
    ];
    final placed = layoutTokens(tokens);
    final a = placed.firstWhere((p) => p.token.id == 'red-0');
    final b = placed.firstWhere((p) => p.token.id == 'blue-0');
    expect(a.size, ludoTokenSize);
    expect(b.size, ludoTokenSize);
    expect(a.x == b.x && a.y == b.y, isFalse);
    final cell = ludoTrack[40];
    expect((a.x - (cell.col + 0.5)).abs(), closeTo(0.24, 1e-9));
    expect((a.y - (cell.row + 0.5)).abs(), closeTo(0.24, 1e-9));
  });

  test('#780 : pion sur la colonne finale en pile : taille réduite', () {
    final base = newLudoGame();
    final tokens = [
      for (final t in base.tokens)
        if (t.id == 'red-0')
          t.copyWith(progress: 52)
        else if (t.id == 'red-1')
          t.copyWith(progress: 52)
        else
          t,
    ];
    final placed = layoutTokens(tokens);
    final a = placed.firstWhere((p) => p.token.id == 'red-0');
    final b = placed.firstWhere((p) => p.token.id == 'red-1');
    expect(a.size, ludoStackSize);
    expect(b.size, ludoStackSize);
  });

  test('#780 : pion seul sur la colonne finale garde sa taille normale', () {
    final state = newLudoGame().copyWith(
      tokens: [
        for (final t in newLudoGame().tokens)
          t.id == 'red-0' ? t.copyWith(progress: 53) : t,
      ],
    );
    final placed =
        layoutTokens(state.tokens).firstWhere((p) => p.token.id == 'red-0');
    expect(placed.size, ludoTokenSize);
  });
}
