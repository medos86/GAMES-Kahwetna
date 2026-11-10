import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

/// Ids d'une combinaison, triés pour comparer sans tenir compte de l'ordre.
Set<String> ids(List<ChkobbaCard> option) => option.map((c) => c.id).toSet();

void main() {
  group('donne de démo « choice » (issue #29)', () {
    test('le joueur a 7 d\'épées, 10 de bâtons et 9 de coupes', () {
      final state = chkobbaDemoChoiceState();
      expect(state.hands[Player.player]!.map((c) => c.id), ['epees-7', 'batons-10', 'coupes-9']);
    });

    test('le tapis contient les six cartes de la source', () {
      final state = chkobbaDemoChoiceState();
      expect(
        state.table.map((c) => c.id).toSet(),
        {'epees-3', 'batons-4', 'coupes-2', 'deniers-5', 'epees-1', 'coupes-6'},
      );
    });

    test('aucune carte n\'apparaît deux fois dans la donne', () {
      final state = chkobbaDemoChoiceState();
      final all = [
        ...state.hands[Player.player]!,
        ...state.hands[Player.opponent]!,
        ...state.table,
        ...state.deck,
      ].map((c) => c.id).toList();
      expect(all.toSet().length, all.length);
      expect(all.length, 40);
    });

    test('jouer le 7 d\'épées ouvre le choix de prise avec les trois combinaisons attendues', () {
      final controller = ChkobbaController(
        targetScore: 11,
        level: ChkobbaAiLevel.facile,
        initialState: chkobbaDemoChoiceState(),
      );
      addTearDown(controller.dispose);

      controller.tapPlayerCard('epees-7');

      final pending = controller.pendingCapture;
      expect(pending, isNotNull, reason: 'un 7 peut prendre plusieurs combinaisons : le dialogue doit s\'ouvrir');
      expect(pending!.cardId, 'epees-7');

      final options = pending.options.map(ids).toList();
      expect(options, contains({'epees-3', 'batons-4'}));
      expect(options, contains({'coupes-2', 'deniers-5'}));
      expect(options, contains({'epees-1', 'coupes-6'}));

      // Écart avec l'issue : la recherche de sous-ensembles de lib/game/chkobba.dart trouve aussi
      // 1 + 2 + 4 (épées 1, coupes 2, bâtons 4). La règle n'est pas modifiée ici : à trancher.
      expect(options.length, 4);
      expect(options, contains({'epees-1', 'coupes-2', 'batons-4'}));
    });
  });
}
