part of '../domino_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({
    required this.unit,
    required this.sm,
    required this.controller,
    required this.seat,
    required this.pile,
  });

  final double unit;
  final bool sm;
  final DominoController controller;

  // Score et avatar du joueur, sur la rangée du bas avec la pioche.
  final Widget seat;

  // Pioche, sur la rangée du bas ; un tap pioche ou passe (#1040).
  final Widget pile;

  void _onTile(
    BuildContext context,
    DominoTile tile,
    bool playable,
    bool canAct,
  ) {
    if (canAct && playable) {
      controller.tapTile(tile);
      return;
    }
    if (canAct) controller.flagInvalid(tile.id);
  }

  void _onDraw(BuildContext context) {
    final game = controller.game;
    final canAct = game.turn == Player.player && game.roundWinner == null;
    if (!canAct || controller.playable.isNotEmpty) {
      // Pas de notification : le bouton tremble pour dire que l'action n'est pas possible.
      controller.flagDrawInvalid();
      return;
    }
    controller.drawOrPass();
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final playable = controller.playable.map((t) => t.id).toSet();
    final canAct = game.turn == Player.player && game.roundWinner == null;
    final label = game.boneyard.isNotEmpty ? t('pickUp') : t('pass');
    final hand = game.hands[Player.player]!;

    // Deux rangées : 1) les pierres de la main ; 2) avatar, score et pioche.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Libellé réduit à la largeur disponible au lieu d'être rogné (#1050).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'TA MAIN · ${hand.length} PIERRES',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
                shadows: [
                  Shadow(offset: Offset(1, 1), color: Color(0xFF123B2B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Rangée 1 : les pierres de la main, pleine largeur.
          SizedBox(
            width: double.infinity,
            height: sm ? 96 : 76,
            child: hand.isEmpty
                ? Center(
                    child: Text(
                      t('emptyHand'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0x9920284B),
                      ),
                    ),
                  )
                : _HandScroller(
                    children: [
                      for (final tile in hand)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: _ShakeOnTrigger(
                            trigger: controller.invalidTileId == tile.id
                                ? controller.invalidCount
                                : 0,
                            child: _HandTile(
                              tile: tile,
                              sm: sm,
                              selected: controller.selectedTileId == tile.id,
                              enabled: canAct && playable.contains(tile.id),
                              onTap: () => _onTile(
                                context,
                                tile,
                                playable.contains(tile.id),
                                canAct,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          // Rangée 2 : avatar et score, puis pioche.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Petit écran : le score rétrécit au lieu de déborder.
              if (MediaQuery.sizeOf(context).width < 340)
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: seat),
                )
              else
                seat,
              const SizedBox(width: 16),
              _ShakeOnTrigger(
                trigger: controller.drawInvalidCount,
                child: Pressable(
                  semanticLabel: game.boneyard.isEmpty
                      ? '$label, ${Strings.dominoDrawUnavailable}'
                      : label,
                  onTap: () => _onDraw(context),
                  child: SizedBox(
                    width: unit * 2.2,
                    child: FittedBox(fit: BoxFit.scaleDown, child: pile),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Main horizontale : quand une pierre est piochée, la main défile jusqu'à la dernière pierre.
class _HandScroller extends StatefulWidget {
  const _HandScroller({required this.children});

  final List<Widget> children;

  @override
  State<_HandScroller> createState() => _HandScrollerState();
}

class _HandScrollerState extends State<_HandScroller> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant _HandScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length > oldWidget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: widget.children,
    );
  }
}
