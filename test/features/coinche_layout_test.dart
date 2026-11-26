// Belote : mise en page du tapis, des sièges et de la distribution (issues #1001 à #1009).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_layout.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('le tapis est un dégradé radial rouge (#1001)', () {
    final gradient = coincheFeltGradient();
    expect(gradient, isA<RadialGradient>());
    expect(gradient.colors, hasLength(3));
    expect(gradient.colors.first, const Color(0xFFEF4444));
  });

  test('la barre du score du haut est retirée (#1002)', () {
    expect(coincheShowTopScoreBar, isFalse);
  });

  test('la marge du tapis est plus serrée qu\'avant (#1003)', () {
    expect(coincheTablePadding.left, lessThan(12));
    expect(coincheTablePadding.right, lessThan(12));
    expect(coincheTablePadding.top, lessThan(12));
  });
}
