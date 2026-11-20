import 'dart:math';

import '../services/profile_store.dart';
import 'avatar_catalog.dart';
import 'avatar_state_rule.dart';
import 'match_avatars.dart';

/// Avatars des sièges d'une partie, siège 0 = joueur local (issues #551 à #555).
///
/// Le pseudo et l'avatar du joueur viennent du profil local ; sans profil
/// lisible, le repli [defaultProfile] est utilisé. Les autres sièges reçoivent
/// des avatars distincts.
Future<List<String>> loadGameAvatars({
  required int seats,
  Random? random,
}) async {
  final profile = await loadProfile();
  return avatarsBySeat(
    seats: seats,
    humanSeat: 0,
    humanId: profile.avatarId,
    random: random,
  );
}

/// État visuel d'un siège : neutre pendant la partie et à égalité,
/// heureux pour un gagnant, fâché pour un perdant.
AvatarState gameAvatarState({
  required int seat,
  required bool finished,
  required List<int> winners,
}) {
  return avatarStateFor(
    outcomeFor(playerId: seat, winners: winners, finished: finished),
  );
}
