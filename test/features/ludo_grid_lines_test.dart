// Angles noirs du plateau Ludo (#664) : les traits de grille doivent être opaques,
// sinon leurs superpositions aux intersections forment des angles sombres.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('#664 : le trait de grille est opaque', () {
    expect(ludoGridLineColor.alpha, 255);
  });

  test("#664 : le trait de grille n'est pas le brun plein du plateau", () {
    expect(ludoGridLineColor, isNot(const Color(0xFF4A2A10)));
  });
}
