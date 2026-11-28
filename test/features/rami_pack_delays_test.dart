import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';
import 'package:kahwetne/widgets/card_motion.dart';

/// Issue #943 : les paquets posés partent un par un, pas tous en même temps.
/// Issue #1057 : le paquet suivant chevauche le précédent (pas de pause visible).
void main() {
  const flight = Duration(milliseconds: 800);

  test('un seul paquet : ses cartes se suivent à 120 ms', () {
    expect(ramiPackDelays([3]), [
      Duration.zero,
      const Duration(milliseconds: 120),
      const Duration(milliseconds: 240),
    ]);
  });

  test('le paquet suivant part à 60 % du vol précédent (#1057)', () {
    final delays = ramiPackDelays([3, 2], flight: flight);
    // Dernière carte du 1er paquet à 240 ms ; le 2e part 480 ms plus tard (60 % de 800 ms).
    expect(delays[3], const Duration(milliseconds: 720));
    expect(delays[4], const Duration(milliseconds: 840));
    expect(delays[3] > delays[2], isTrue);
  });

  test('le chevauchement est plus court que la pause de 400 ms (#1057)', () {
    final delays = ramiPackDelays([1, 1], flight: flight);
    // Avant : 400 ms d'attente entre les deux paquets. Maintenant : 480 ms de départ décalé.
    expect(delays[1] - delays[0], const Duration(milliseconds: 480));
  });

  test('les paquets vides et la liste vide ne produisent aucun délai', () {
    expect(ramiPackDelays(const []), isEmpty);
    expect(ramiPackDelays([0, 0]), isEmpty);
    expect(ramiPackDelays([0, 2]), [
      Duration.zero,
      const Duration(milliseconds: 120),
    ]);
  });

  test('chaque carte garde un délai au plus égal à la suivante', () {
    final delays = ramiPackDelays([4, 1, 3], flight: flight);
    expect(delays.length, 8);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i] >= delays[i - 1], isTrue);
    }
  });

  test('un vol adverse utilise une décélération à l’arrivée (#1057)', () {
    const flight = CardFlight(
      from: Rect.zero,
      to: _noTarget,
      child: SizedBox(),
      curve: Curves.easeOutCubic,
    );
    expect(flight.curve, Curves.easeOutCubic);
  });

  test('un vol par défaut garde la courbe d’origine', () {
    const flight = CardFlight(
      from: Rect.zero,
      to: _noTarget,
      child: SizedBox(),
    );
    expect(flight.curve, Curves.easeInOutCubic);
  });
}

Rect? _noTarget() => null;
