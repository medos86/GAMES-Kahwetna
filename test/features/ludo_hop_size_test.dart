// Taille d'un pion pendant son déplacement (#798) : pleine en route, réduite à l'arrivée.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';

void main() {
  test('#798 : un pion en mouvement garde sa taille pleine', () {
    expect(
      ludoVisualBaseSize(moving: true, placedSize: ludoStackSize),
      ludoTokenSize,
    );
  });

  test('#798 : pion arrivé en pile, taille réduite', () {
    expect(
      ludoVisualBaseSize(moving: false, placedSize: ludoStackSize),
      ludoStackSize,
    );
  });

  test('#798 : un pion seul arrivé garde la taille normale', () {
    expect(
      ludoVisualBaseSize(moving: false, placedSize: ludoTokenSize),
      ludoTokenSize,
    );
  });
}
