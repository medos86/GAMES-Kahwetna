part of '../domino_screen.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.difficulty,
    required this.unit,
    required this.round,
    required this.target,
    required this.onMenu,
  });

  final Difficulty difficulty;
  final double unit;
  final int round;
  final int target;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return GameHeader(
      unit: unit,
      onMenu: onMenu,
      center: Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: unit * 0.5),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'Manche $round',
                    style: TextStyle(
                      fontSize: unit * 0.8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 2),
                          color: ComicPalette.ink,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      trailing: TrophyBadge(
        target: target,
        size: unit * 3,
        tint: difficultyTint(difficulty),
      ),
    );
  }
}

/// État visuel de l'avatar d'un joueur (issue #555) : neutre pendant la manche,
/// heureux pour le gagnant de la manche, fâché pour l'autre.
AvatarState dominoAvatarState(DominoState game, Player player) {
  final winner = game.roundWinner;
  return gameAvatarState(
    seat: player.index,
    finished: winner != null,
    winners: winner == null ? const [] : [winner.index],
  );
}

/// Taille de l'avatar inactif et de l'avatar du joueur dont c'est le tour, en dp.
/// Mêmes tailles que le Chkobba (`_SidePanel`).
const double _seatAvatarActiveSize = 48;

/// Coin d'un joueur, affiché comme au Chkobba (`_SidePanel`) : avatar en médaillon,
/// pastille du pseudo, puis pastille du score.
class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.unit,
    required this.avatarId,
    required this.avatarState,
  });

  /// Pseudo affiché sous l'avatar.
  final String label;
  final int value;
  final Color color;
  final bool active;
  final double unit;

  // Avatar du joueur et son état (issue #555).
  final String avatarId;
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    final avatar = TurnAvatar(
      tone: color,
      active: active,
      avatarId: avatarId,
      state: avatarState,
      semanticLabel: label,
      // Même taille pour les deux joueurs, actif ou non (#1039).
      baseSize: _seatAvatarActiveSize,
      activeSize: _seatAvatarActiveSize,
    );
    // Anneau 3D couleur du joueur, comme au Chkobba.
    final ring = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 3),
            blurRadius: 2,
          ),
        ],
      ),
      child: avatar,
    );
    return Semantics(
      container: true,
      label: tf('sScoreOf', {
        'who': label == t('you') ? t('youLower') : t('opponent'),
        'v': '$value',
      }),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _seatAvatarActiveSize + 8,
            height: _seatAvatarActiveSize + 8,
            child: Center(child: ring),
          ),
          const SizedBox(height: 2),
          _NamePill(name: label, active: active),
          const SizedBox(height: 4),
          _ScorePill(score: value, color: color),
        ],
      ),
    );
  }
}

/// Pastille du pseudo, comme au Chkobba : dorée quand c'est son tour, sombre sinon.
class _NamePill extends StatelessWidget {
  const _NamePill({required this.name, required this.active});

  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            active ? ComicPalette.gold : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? ComicPalette.ink : Colors.black26,
          width: 2,
        ),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: active ? const Color(0xFF513B00) : ComicPalette.white,
        ),
      ),
    );
  }
}

/// Pastille du score, comme au Chkobba : fond blanc, chiffre à la couleur du joueur.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ComicPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '$score',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}
