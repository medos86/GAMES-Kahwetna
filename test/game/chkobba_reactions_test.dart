import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/reactions/reaction_mood.dart';
import 'package:kahwetne/game/chkobba_reactions.dart';
import 'package:kahwetne/game/common.dart';

void main() {
  group('chkobbaReactions', () {
    test('sans action, aucune réaction', () {
      expect(chkobbaReactions(), isEmpty);
    });

    test('Chkobba : aucun sticker', () {
      expect(chkobbaReactions(chkobba: Player.player), isEmpty);
      expect(chkobbaReactions(chkobba: Player.opponent), isEmpty);
    });

    test('7AYA : aucun sticker', () {
      expect(chkobbaReactions(haya: Player.opponent), isEmpty);
    });

    test('prise simple : seul le capteur rit', () {
      expect(chkobbaReactions(capturer: Player.opponent), {
        Player.opponent: ReactionMood.laugh,
      });
    });

    test('Chkobba et prise : aucun sticker', () {
      expect(
        chkobbaReactions(chkobba: Player.player, capturer: Player.player),
        isEmpty,
      );
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
