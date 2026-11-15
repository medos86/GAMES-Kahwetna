import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart' as chk;
import 'package:kahwetne/game/coinche.dart' as coi;
import 'package:kahwetne/game/domino_ai.dart' as dom;
import 'package:kahwetne/game/ludo.dart' as lud;
import 'package:kahwetne/game/rami.dart' as ram;

/// Issue #303 : chaque jeu reçoit le niveau IA de même nom que la difficulté choisie.
void main() {
  test('aiLevelFor : même nom que la difficulté, pour les cinq jeux', () {
    for (final d in Difficulty.values) {
      expect(aiLevelFor(chk.ChkobbaAiLevel.values, d).name, d.name);
      expect(aiLevelFor(coi.CoincheAiLevel.values, d).name, d.name);
      expect(aiLevelFor(dom.DominoAiLevel.values, d).name, d.name);
      expect(aiLevelFor(lud.LudoAiLevel.values, d).name, d.name);
      expect(aiLevelFor(ram.RamiAiLevel.values, d).name, d.name);
    }
  });
}
