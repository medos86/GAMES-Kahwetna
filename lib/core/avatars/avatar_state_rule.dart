import 'avatar_catalog.dart';

/// Résultat d'un joueur pour l'affichage de son avatar (issue #556).
enum RoundOutcome { playing, won, lost, tie }

/// Résultat d'un joueur, selon la fin de la manche ou de la partie.
/// [finished] faux : le joueur est encore en jeu. [winners] vide : égalité.
RoundOutcome outcomeFor({
  required int playerId,
  required List<int> winners,
  required bool finished,
}) {
  if (!finished) return RoundOutcome.playing;
  if (winners.isEmpty) return RoundOutcome.tie;
  return winners.contains(playerId) ? RoundOutcome.won : RoundOutcome.lost;
}

/// État visuel de l'avatar : neutre pendant la partie et à égalité,
/// heureux pour le gagnant, fâché pour le perdant (jamais fâché en cours de partie).
AvatarState avatarStateFor(RoundOutcome outcome) {
  return switch (outcome) {
    RoundOutcome.won => AvatarState.happy,
    RoundOutcome.lost => AvatarState.angry,
    RoundOutcome.playing => AvatarState.neutral,
    RoundOutcome.tie => AvatarState.neutral,
  };
}
