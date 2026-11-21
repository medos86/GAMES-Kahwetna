// Animation de capture Ludo (#662) : fonctions pures de saut, d'agrandissement et de catapulte.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';

void main() {
  test('#662 : le saut est nul aux extrémités du segment', () {
    expect(ludoLiftAt(0, capture: true, lastCells: true), 0);
    expect(ludoLiftAt(1, capture: true, lastCells: true), closeTo(0, 1e-9));
  });

  test('#662 : saut de capture plus haut sur les deux dernières cases', () {
    final normal = ludoLiftAt(0.5, capture: false, lastCells: false);
    final onLast = ludoLiftAt(0.5, capture: true, lastCells: true);
    final earlier = ludoLiftAt(0.5, capture: true, lastCells: false);
    expect(normal, closeTo(ludoHopHeight, 1e-9));
    expect(onLast, closeTo(ludoCaptureHopHeight, 1e-9));
    expect(onLast, greaterThan(normal));
    expect(earlier, closeTo(normal, 1e-9));
  });

  test('#662 : la victime s\'élève en arc et retombe sur sa case', () {
    expect(ludoCatapultLift(0), 0);
    expect(ludoCatapultLift(0.5), closeTo(ludoCatapultHeight, 1e-9));
    expect(ludoCatapultLift(1), closeTo(0, 1e-9));
  });

  test('#662 : l\'attaquant grandit au sommet de son saut', () {
    expect(ludoCaptureScale(0), 1);
    expect(ludoCaptureScale(1), closeTo(1, 1e-9));
    expect(ludoCaptureScale(0.5), closeTo(ludoCaptureMaxScale, 1e-9));
    expect(ludoCaptureMaxScale, greaterThan(1));
  });

  test('#662 : la victime part après l\'attaquant', () {
    expect(ludoVictimDelayMs, greaterThan(0));
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
}
