import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/reactions/reaction_mood.dart';
import 'package:kahwetne/game/chkobba_reactions.dart';
import 'package:kahwetne/game/common.dart';

void main() {
  group('chkobbaReactions', () {
    test('sans action, aucune réaction', () {
      expect(chkobbaReactions(), isEmpty);
    });

    test('Chkobba : aucun sticker, l\'éclat BD suffit', () {
      expect(chkobbaReactions(chkobba: Player.player), isEmpty);
      expect(chkobbaReactions(chkobba: Player.opponent), isEmpty);
    });

    test('7AYA : aucun sticker, l\'éclat BD suffit', () {
      expect(chkobbaReactions(haya: Player.opponent), isEmpty);
    });

    test('prise simple : seul le capteur rit', () {
      expect(chkobbaReactions(capturer: Player.opponent), {
        Player.opponent: ReactionMood.laugh,
      });
    });

    test('Chkobba et prise : aucun sticker, un seul élément BD', () {
      expect(
        chkobbaReactions(chkobba: Player.player, capturer: Player.player),
        isEmpty,
      );
    });
  });

  group('chkobbaBurstText', () {
    test('sans action, aucun éclat', () {
      expect(chkobbaBurstText(), isNull);
    });

    test('Chkobba seule : « Chkobba ! »', () {
      expect(chkobbaBurstText(chkobba: Player.opponent), 'Chkobba !');
    });

    test('7AYA seule : « ♦ 7AYA ! »', () {
      expect(chkobbaBurstText(haya: Player.player), '♦ 7AYA !');
    });

    test('Chkobba et 7AYA en même temps : la Chkobba l\'emporte', () {
      expect(
        chkobbaBurstText(chkobba: Player.player, haya: Player.player),
        'Chkobba !',
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
