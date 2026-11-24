// Animation de capture Ludo (#662, #882) : fonctions pures de saut, de catapulte et de galipette.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('#662 : le saut est nul aux extrémités du segment', () {
    expect(ludoLiftAt(0), 0);
    expect(ludoLiftAt(1), closeTo(0, 1e-9));
    expect(ludoLiftAt(0.5), closeTo(ludoHopHeight, 1e-9));
  });

  test('#882 : le pion qui capture saute comme un pion ordinaire', () {
    expect(ludoLiftAt(0.5), closeTo(ludoHopHeight, 1e-9));
    expect(ludoHopMsPerCellFor(fromBase: false), ludoHopMsPerCell);
  });

  test('#662 : la victime s\'élève en arc et retombe sur sa case', () {
    expect(ludoCatapultLift(0), 0);
    expect(ludoCatapultLift(0.5), closeTo(ludoCatapultHeight, 1e-9));
    expect(ludoCatapultLift(1), closeTo(0, 1e-9));
  });

  test('#882 : la victime part après l\'arrivée de l\'attaquant', () {
    const before = [
      Token(id: 'b0', color: LudoColor.blue, progress: 1),
      Token(id: 'r0', color: LudoColor.red, progress: 10),
    ];
    const after = [
      Token(id: 'b0', color: LudoColor.blue, progress: 2),
      Token(id: 'r0', color: LudoColor.red, progress: 0),
    ];
    final delay = ludoVictimDelayFor(before, after);
    expect(delay, greaterThan(0));
    // Un déplacement sans capture n'attend rien.
    const noCapture = [
      Token(id: 'b0', color: LudoColor.blue, progress: 2),
      Token(id: 'r0', color: LudoColor.red, progress: 10),
    ];
    expect(ludoVictimDelayFor(before, noCapture), 0);
  });

  // Régression #679 : une reconstruction du plateau sans déplacement ne doit pas
  // interrompre l'animation de capture en cours.
  test('#679 : progression inchangée = on ne touche à rien', () {
    expect(ludoHopAction(from: 12, to: 12, reduced: false), LudoHopAction.keep);
    expect(ludoHopAction(from: 0, to: 0, reduced: false), LudoHopAction.keep);
    expect(ludoHopAction(from: 12, to: 12, reduced: true), LudoHopAction.keep);
  });

  test('#679 : déplacement animé, ou direct si animations désactivées', () {
    expect(ludoHopAction(from: 3, to: 9, reduced: false), LudoHopAction.play);
    expect(ludoHopAction(from: 3, to: 9, reduced: true), LudoHopAction.instant);
    expect(ludoHopAction(from: 5, to: 0, reduced: false), LudoHopAction.play);
  });

  // #869 : galipettes de la victime pendant sa catapulte.
  test('#869 : la victime fait des galipettes pendant sa catapulte', () {
    expect(ludoVictimSpinAngle(0), 0);
    expect(ludoVictimSpinAngle(0.5), closeTo(2 * 3.141592653589793, 1e-9));
    expect(ludoVictimSpinAngle(1), closeTo(4 * 3.141592653589793, 1e-9));
  });

  // #869 : sortie de base plus rapide que la marche normale.
  test('#869 : sortie de base plus rapide', () {
    expect(ludoFastHopMsPerCell, lessThan(ludoHopMsPerCell));
    expect(ludoHopMsPerCellFor(fromBase: true), ludoFastHopMsPerCell);
    expect(ludoHopMsPerCellFor(fromBase: false), ludoHopMsPerCell);
  });
}
