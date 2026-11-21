// Avatar du joueur actif au Ludo (#665) : taille et respiration, fonctions pures.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';

void main() {
  test('#665 : le joueur actif a un avatar plus grand que les autres', () {
    expect(
      ludoAvatarSizeFor(active: true),
      greaterThan(ludoAvatarSizeFor(active: false)),
    );
    expect(ludoAvatarSizeFor(active: false), ludoAvatarSize);
  });

  test('#665 : la respiration reste entre 1 et 1,05', () {
    for (var i = 0; i <= 20; i++) {
      final scale = ludoBreathScale(i / 20);
      expect(scale, greaterThanOrEqualTo(1 - 1e-9));
      expect(scale, lessThanOrEqualTo(1.05 + 1e-9));
    }
  });

  test('#665 : la respiration part de 1, atteint 1,05 au milieu du cycle', () {
    expect(ludoBreathScale(0), closeTo(1, 1e-9));
    expect(ludoBreathScale(0.5), closeTo(1.05, 1e-9));
    expect(ludoBreathScale(1), closeTo(1, 1e-9));
  });
}
