import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/rami.dart' as rules;

// Main non triée au début de partie (#877) : l'ordre affiché est celui de la distribution.
void main() {
  test('la main affichée au début garde l\'ordre de distribution', () {
    final c = RamiController(
      targetScore: 100,
      difficulty: rules.RamiAiLevel.facile,
      random: () => 0.3,
    );
    final dealt = [for (final card in c.hand) card.id];
    expect([for (final card in c.displayed) card.id], dealt);
    c.dispose();
  });
}
