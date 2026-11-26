// Réactions BD du Chkobba (#759, #788, #chkobba-bd). Dart pur : aucun import Flutter.

import '../core/reactions/reaction_mood.dart';
import 'common.dart';

/// Un seul élément BD par coup : Chkobba ou 7AYA sans sticker, sinon sticker de prise simple.
///
/// Les éclats « Chkobba ! » et « 7AYA ! » ne s'affichent plus sur le tapis (#964).
///
/// [capturer] : joueur qui fait une prise simple : seul son avatar rit.
Map<Player, ReactionMood> chkobbaReactions({
  Player? chkobba,
  Player? haya,
  Player? capturer,
}) {
  if (chkobba != null || haya != null) return const {};
  if (capturer == null) return const {};
  return {capturer: ReactionMood.laugh};
}
