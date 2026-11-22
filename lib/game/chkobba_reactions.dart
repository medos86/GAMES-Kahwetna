// Réactions d'avatar du Chkobba (#759, #788). Dart pur : aucun import Flutter.

import '../core/reactions/reaction_mood.dart';
import 'common.dart';

/// Humeur de l'avatar de chaque joueur après un coup.
///
/// [chkobba] : joueur qui fait une Chkobba (il rit, l'autre est choqué).
/// [haya] : joueur qui ramasse le 7 de deniers (surprise).
/// [capturer] : joueur qui fait une prise simple (il rit, l'autre réfléchit).
/// Priorité : Chkobba, puis Haya, puis prise simple.
Map<Player, ReactionMood> chkobbaReactions({
  Player? chkobba,
  Player? haya,
  Player? capturer,
}) {
  final moods = <Player, ReactionMood>{};
  if (capturer != null) {
    moods[capturer] = ReactionMood.laugh;
    moods[other(capturer)] = ReactionMood.thinking;
  }
  if (haya != null) moods[haya] = ReactionMood.surprise;
  if (chkobba != null) {
    moods[chkobba] = ReactionMood.laugh;
    moods[other(chkobba)] = ReactionMood.shock;
  }
  return moods;
}
