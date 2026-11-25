// Réactions BD du Chkobba (#759, #788, #chkobba-bd). Dart pur : aucun import Flutter.

import '../core/reactions/reaction_mood.dart';
import 'common.dart';

/// Un seul élément BD par coup : Chkobba, puis 7AYA, puis sticker de prise simple.
///
/// Une Chkobba ou une 7AYA affiche l'éclat au centre du tapis ([chkobbaBurstText])
/// et aucun sticker : moins d'animations en même temps, rien ne se superpose.
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

/// Texte de l'unique éclat BD du tapis, ou null. La Chkobba l'emporte sur la 7AYA.
String? chkobbaBurstText({Player? chkobba, Player? haya}) {
  if (chkobba != null) return 'Chkobba !';
  if (haya != null) return '♦ 7AYA !';
  return null;
}
