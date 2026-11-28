import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('#1071 : le lancer joue pendant la phase move', () {
    expect(ludoDieShouldTumble(true, LudoPhase.move), isTrue);
  });

  test('#1071 : pas de relance après le déplacement du pion', () {
    expect(ludoDieShouldTumble(true, LudoPhase.roll), isFalse);
  });

  test('#1071 : pas de lancer si le dé n a pas été lancé ici', () {
    expect(ludoDieShouldTumble(false, LudoPhase.move), isFalse);
  });
}
