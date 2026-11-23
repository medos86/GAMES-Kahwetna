// Pas du pion et pointe au centre de la case (issue #837).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';

void main() {
  test('la pointe du pion tombe au centre : décalage de la moitié de sa hauteur', () {
    expect(ludoPawnTipShift(10), closeTo(-6, 1e-9));
    expect(ludoPawnTipShift(0), 0);
  });

  test('un son de pas est joué à chaque case franchie', () {
    expect(ludoStepTriggers(0, 1), isTrue);
    expect(ludoStepTriggers(3, 4), isTrue);
  });

  test('pas de son de pas sans nouvelle case', () {
    expect(ludoStepTriggers(2, 2), isFalse);
    expect(ludoStepTriggers(2, 1), isFalse);
  });

  test('le son de pas existe et est prévu pour le Ludo', () {
    expect(Sfx.pawnStep.assetPath, 'assets/sounds/ludo/pawn_step.wav');
    expect(File(Sfx.pawnStep.assetPath).existsSync(), isTrue);
    expect(gameSfx['ludo'], contains(Sfx.pawnStep));
  });
}
