import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';

// Cartes du tapis lisibles (#908) : largeur minimale garantie.
void main() {
  test('les cartes posées sur le tapis gardent une largeur lisible', () {
    expect(kChkobbaTableCardWidth, greaterThanOrEqualTo(64));
  });
}
