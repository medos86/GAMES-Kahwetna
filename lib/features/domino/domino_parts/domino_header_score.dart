part of '../domino_screen.dart';

class _WoodShadeBackground extends StatelessWidget {
  const _WoodShadeBackground();

  @override
  Widget build(BuildContext context) {
    // Dégradé d'ombre en haut : approximation des couches de bois du source.
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4D000000), Color(0x00000000)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

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
                          color: Color(0xFF4A2A10),
                        ),
                      ],
                    ),
                  ),
                  DifficultyChip(difficulty: difficulty),
                ],
              ),
            ],
          ),
        ),
      ),
      trailing: SizedBox(
        width: unit * 3,
        height: unit * 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: unit * 3,
              color: const Color(0xFFFBBF24),
            ),
            Positioned(
              top: unit * 0.4,
              child: Text(
                '$target',
                style: TextStyle(
                  fontSize: unit * 0.8,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF20284B),
                ),
              ),
            ),
          ],
        ),
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

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({
    required this.unit,
    required this.game,
    required this.avatarIds,
    required this.turnIsPlayer,
    required this.turnIsOpponent,
    required this.onDrawTap,
    required this.mustDraw,
  });

  final double unit;
  final DominoState game;

  // Avatar de chaque joueur, indexé par Player (issue #555).
  final List<String> avatarIds;
  final bool turnIsPlayer;
  final bool turnIsOpponent;
  final VoidCallback onDrawTap;
  final bool mustDraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2A10), spreadRadius: 3),
          BoxShadow(
            color: Color(0xFF4A2A10),
            offset: Offset(0, 4),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Points de la barre de score : radial-gradient #000 1px, 6px, opacité 0.1.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const DotPattern(
                spacing: 6,
                radius: 1,
                color: Color(0x1A000000),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreBox(
                label: t('you'),
                value: game.scores[Player.player]!,
                color: const Color(0xFF047857),
                active: turnIsPlayer,
                unit: unit,
                avatarId: avatarIds[Player.player.index],
                avatarState: dominoAvatarState(game, Player.player),
              ),
              _Pile(
                unit: unit,
                count: game.boneyard.length,
                bounce: mustDraw && game.boneyard.isNotEmpty,
              ),
              _ScoreBox(
                label: t('opponentShort'),
                value: game.scores[Player.opponent]!,
                color: const Color(0xFFB91C1C),
                active: turnIsOpponent,
                unit: unit,
                avatarId: avatarIds[Player.opponent.index],
                avatarState: dominoAvatarState(game, Player.opponent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarView(
            avatarId: avatarId,
            state: avatarState,
            size: unit * 2,
            semanticLabel: label,
          ),
          SizedBox(width: unit * 0.3),
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
              boxShadow: active
                  ? const [BoxShadow(color: Color(0xFFFFF1BD), spreadRadius: 3)]
                  : null,
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
    );
  }
}
