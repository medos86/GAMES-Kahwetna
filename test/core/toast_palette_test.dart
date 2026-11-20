// Couleurs des toasts passées par le thème (#64) : une couleur par gravité.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';

void main() {
  test('chaque gravité de toast a sa couleur d accent distincte', () {
    final accents = {
      ToastPalette.info,
      ToastPalette.success,
      ToastPalette.error,
    };
    expect(accents.length, 3);
  });
}
