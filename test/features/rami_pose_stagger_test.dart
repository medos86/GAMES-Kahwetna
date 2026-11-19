import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Pose de paquets Rami carte par carte (#592) : décalage et place de chaque carte.
void main() {
  test('les cartes d\'un paquet posé partent une à une, 120 ms d\'écart', () {
    expect(ramiPoseDelay(0), Duration.zero);
    expect(ramiPoseDelay(1), const Duration(milliseconds: 120));
    expect(ramiPoseDelay(3), const Duration(milliseconds: 360));
  });

  test('chaque carte d\'un paquet vise une place différente', () {
    const width = 50.0;
    final lefts = [
      for (var i = 0; i < 3; i++) ramiMeldSlotLeft(100, width, i),
    ];
    expect(lefts[0], 100);
    expect(lefts[1], closeTo(100 + width * ramiMeldStepRatio, 1e-9));
    expect(lefts[2], closeTo(100 + 2 * width * ramiMeldStepRatio, 1e-9));
    expect(lefts.toSet().length, 3);
  });
}
