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

const _activeGlow = [BoxShadow(color: Color(0xFFFFF1BD), spreadRadius: 3)];

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
    return Semantics(
      label: tf('sScoreOf', {
        'who': label == t('you') ? t('youLower') : t('opponent'),
        'v': '$value',
      }),
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'Adv.') ...[
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: unit * 0.7,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                SizedBox(width: unit * 0.3),
              ],
              Container(
                constraints: BoxConstraints(minWidth: unit * 3.2),
                height: unit * 2.8,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                  boxShadow: active ? _activeGlow : null,
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: unit * 1.4,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              if (label == t('you')) ...[
                SizedBox(width: unit * 0.3),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: unit * 0.7,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
          // Avatar posé au-dessus de la pastille : il ne change pas la largeur.
          Positioned(
            top: -unit * 1.3,
            child: AvatarView(
              avatarId: avatarId,
              state: avatarState,
              size: unit * 1.8,
              semanticLabel: label,
            ),
          ),
        ],
      ),
    );
  }
}
