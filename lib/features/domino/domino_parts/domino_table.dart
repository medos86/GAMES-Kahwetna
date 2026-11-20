part of '../domino_screen.dart';

class _Pile extends StatelessWidget {
  const _Pile({required this.unit, required this.count, required this.bounce});

  final double unit;
  final int count;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tf('sBoneyard', {'n': '$count'}),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: unit * 2,
            height: unit * 2,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: unit,
                  height: unit * 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC63D55),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
                Positioned(
                  right: -unit * 0.2,
                  top: -unit * 0.2,
                  child: Container(
                    constraints: BoxConstraints(minWidth: unit * 0.9),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: unit * 0.55,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF20284B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            t('draw'),
            style: TextStyle(
              fontSize: unit * 0.55,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: const Color(0xFF17213D),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentHand extends StatelessWidget {
  const _OpponentHand({
    required this.unit,
    required this.count,
    required this.avatarId,
    required this.avatarState,
  });

  final double unit;
  final int count;

  // Avatar de l'adversaire et son état (issue #555).
  final String avatarId;
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: unit * 3.4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _cards(),
          // Avatar à gauche de la main, sans la décaler.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: AvatarView(
                avatarId: avatarId,
                state: avatarState,
                size: unit * 2.2,
                semanticLabel: t('opponent'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: unit * 0.15),
            child: Container(
              width: unit * 1.9,
              height: unit * 3.4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD94A61), Color(0xFF8F203D)],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _edge, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF4A1022), offset: Offset(0, 3)),
                ],
              ),
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(height: 2, color: const Color(0xB3FFE16B)),
              ),
            ),
          ),
      ],
    );
  }
}

const _edge = Color(0xFF24364B);

class _Table extends StatelessWidget {
  const _Table({
    required this.unit,
    required this.sm,
    required this.controller,
  });

  final double unit;
  final bool sm;
  final DominoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final status = _status(controller);
    final ends = controller.chainEnds;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sm ? 20 : 8,
        vertical: sm ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4A2A10), width: 6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2A10), spreadRadius: 3),
          BoxShadow(
            color: Color(0x59281405),
            offset: Offset(0, 8),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Tapis : rayures blanches 4px (opacité 0.08 × 0.08), points noirs 8px (opacité 0.1).
            const Positioned.fill(
              child: StripePattern(
                period: 4,
                width: 2,
                color: Color(0x02FFFFFF),
              ),
            ),
            const Positioned.fill(
              child: StripePattern(
                period: 4,
                width: 2,
                color: Color(0x02FFFFFF),
                vertical: true,
              ),
            ),
            const Positioned.fill(
              child: DotPattern(
                spacing: 8,
                radius: 1,
                color: Color(0x1A000000),
              ),
            ),
            Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: sm ? 14 : 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(offset: Offset(1, 1), color: Color(0xFF123B2B)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sm ? 6 : 8),
                Expanded(
                  child: game.chain.isEmpty
                      ? Center(
                          child: Text(
                            'La première pierre ouvre la partie',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        )
                      : DominoChain(
                          chain: game.chain,
                          leftOpen: ends?.left ?? false,
                          rightOpen: ends?.right ?? false,
                          onEndTap: controller.playSelected,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _status(DominoController c) {
    final game = c.game;
    if (game.roundWinner != null) return 'Manche terminée';
    final playerTurn = game.turn == Player.player;
    if (game.chain.isEmpty) {
      return playerTurn
          ? 'À toi d’ouvrir la chaîne'
          : 'Le voisin ouvre la chaîne…';
    }
    if (!playerTurn) return 'Le voisin réfléchit…';
    if (c.selectedTile != null) return 'Touche l’extrémité où poser la pierre';
    if (c.playable.isNotEmpty) return 'Touche une pierre pour jouer';
    return game.boneyard.isNotEmpty
        ? 'Aucun coup possible : pioche'
        : 'Aucun coup possible : passe';
  }
}
