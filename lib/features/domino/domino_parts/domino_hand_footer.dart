part of '../domino_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({
    required this.unit,
    required this.sm,
    required this.controller,
  });

  final double unit;
  final bool sm;
  final DominoController controller;

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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ComicPalette.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: ComicPalette.ink, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TA MAIN · ${game.hands[Player.player]!.length} PIERRES',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFF20284B),
                  ),
                ),
              ),
              _ShakeOnTrigger(
                trigger: controller.drawInvalidCount,
                child: Pressable(
                  semanticLabel: game.boneyard.isEmpty
                      ? '$label, ${Strings.dominoDrawUnavailable}'
                      : label,
                  onTap: () => _onDraw(context),
                  child: kComicDomino
                      ? _comicDrawChip(label)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5A3C), Color(0xFFD71920)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4A0A0A),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFFF8A4C),
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: sm ? 96 : 76,
            child: game.hands[Player.player]!.isEmpty
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
                      for (final tile in game.hands[Player.player]!)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
