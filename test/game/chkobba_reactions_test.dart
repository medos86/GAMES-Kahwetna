import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/reactions/reaction_mood.dart';
import 'package:kahwetne/game/chkobba_reactions.dart';
import 'package:kahwetne/game/common.dart';

void main() {
  group('chkobbaReactions', () {
    test('sans action, aucune réaction', () {
      expect(chkobbaReactions(), isEmpty);
    });

    test('Chkobba du joueur : il rit, l\'adversaire est choqué', () {
      final moods = chkobbaReactions(chkobba: Player.player);
      expect(moods, {
        Player.player: ReactionMood.laugh,
        Player.opponent: ReactionMood.shock,
      });
    });

    test('Chkobba de l\'adversaire : inversé', () {
      final moods = chkobbaReactions(chkobba: Player.opponent);
      expect(moods, {
        Player.opponent: ReactionMood.laugh,
        Player.player: ReactionMood.shock,
      });
    });

    test('Haya seule : surprise pour celui qui la ramasse', () {
      final moods = chkobbaReactions(haya: Player.opponent);
      expect(moods, {Player.opponent: ReactionMood.surprise});
    });

    test('Chkobba et Haya du même joueur : la Chkobba l\'emporte', () {
      final moods = chkobbaReactions(
        chkobba: Player.player,
        haya: Player.player,
      );
      expect(moods[Player.player], ReactionMood.laugh);
    });
  });

  group('ReactionMood', () {
    test('chaque humeur a un sticker distinct dans le dossier reactions', () {
      final paths = ReactionMood.values.map((m) => m.assetPath).toList();
      expect(paths.toSet().length, ReactionMood.values.length);
      for (final path in paths) {
        expect(path, startsWith('assets/images/reactions/'));
        expect(path, endsWith('.png'));
      }
    });
  });
}
