// Réactions d'avatar du Chkobba (#759). Dart pur : aucun import Flutter.

import '../core/reactions/reaction_mood.dart';
import 'common.dart';

/// Humeur de l'avatar de chaque joueur après un coup.
///
/// [chkobba] : joueur qui fait une Chkobba (il rit, l'autre est choqué).
/// [haya] : joueur qui ramasse le 7 de deniers (surprise).
/// Une Chkobba l'emporte sur la Haya du même joueur.
Map<Player, ReactionMood> chkobbaReactions({Player? chkobba, Player? haya}) {
  final moods = <Player, ReactionMood>{};
  if (haya != null) moods[haya] = ReactionMood.surprise;
  if (chkobba != null) {
    moods[chkobba] = ReactionMood.laugh;
    moods[other(chkobba)] = ReactionMood.shock;
  }
  return moods;
}
