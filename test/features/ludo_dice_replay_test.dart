import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('#1071 : le lancer joue pendant la phase move du joueur qui a lancé', () {
    expect(
      ludoDieShouldTumble(rolledHere: true, phase: LudoPhase.move),
      isTrue,
    );
  });

  test('#1071 : pas de relance après le déplacement du pion', () {
    expect(
      ludoDieShouldTumble(rolledHere: true, phase: LudoPhase.roll),
      isFalse,
    );
  });

  test('#1071 : pas de lancer pour un dé qui ne vient pas d être lancé', () {
    expect(
      ludoDieShouldTumble(rolledHere: false, phase: LudoPhase.move),
      isFalse,
    );
  });
}
