// Tapis armé dès qu'une carte ou un groupe est sélectionné (pose à gauche, à droite ou nouveau paquet).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';

void main() {
  test('le tapis est armé dès qu\'une carte est sélectionnée', () {
    expect(
      ramiTableArmed(canPlay: true, dragging: false, selectedCount: 1),
      isTrue,
    );
  });

  test('le tapis est armé pour un groupe sélectionné (jokers compris)', () {
    expect(
      ramiTableArmed(canPlay: true, dragging: false, selectedCount: 3),
      isTrue,
    );
  });

  test('le tapis est armé pendant un glisser sans sélection', () {
    expect(
      ramiTableArmed(canPlay: true, dragging: true, selectedCount: 0),
      isTrue,
    );
  });

  test('le tapis reste neutre sans sélection ni glisser', () {
    expect(
      ramiTableArmed(canPlay: true, dragging: false, selectedCount: 0),
      isFalse,
    );
  });

  test('le tapis n\'est jamais armé hors de mon tour de pose', () {
    expect(
      ramiTableArmed(canPlay: false, dragging: true, selectedCount: 2),
      isFalse,
    );
  });
}
