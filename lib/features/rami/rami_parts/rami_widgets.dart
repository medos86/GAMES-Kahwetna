part of '../rami_screen.dart';

// ---------------------------------------------------------------------------

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.seat,
    required this.game,
    required this.avatarId,
    required this.avatarState,
  });

  final int seat;
  final rules.RamiState game;

  /// Avatar devant le score (issue #552).
  final String avatarId;
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    final active = game.turn == seat && game.phase != rules.RamiPhase.end;
    final points = game.openings[seat];
    final opened = game.opened[seat]
        ? (points > 0 ? 'Ouvert $points' : 'Ouvert')
        : 'Fermé';
    final ink = active ? const Color(0xFF513B00) : _inkColor;
    return Semantics(
      label: '${_seatNames[seat]} : ${game.scores[seat]} points, $opened',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: active ? _goldColor : _creamColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _frameColor.withValues(alpha: active ? 1 : 0.6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarView(
                  avatarId: avatarId,
                  state: avatarState,
                  size: 22,
                  semanticLabel: _seatNames[seat],
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _seatNames[seat].toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (game.dealer == seat) ...[
                  const SizedBox(width: 3),
                  const CircleAvatar(
                    radius: 7,
                    backgroundColor: _inkColor,
                    child: Text(
                      'D',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${game.scores[seat]}',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              seat == 0 ? opened : '×${game.hands[seat].length} · $opened',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combinaison de la table : cartes qui se chevauchent, comme les piles du source.
/// Bordure et étiquette à la couleur du joueur qui a posé le paquet (#537).
class _MeldView extends StatelessWidget {
  const _MeldView({
    required this.cards,
    required this.cardWidth,
    this.owner = -1,
    this.hot = false,
    this.eligible = false,
    this.onTap,
  });

  final List<rules.RamiCard> cards;
  final double cardWidth;
  final int owner;
  final bool hot;
  final bool eligible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final step = cardWidth * ramiMeldStepRatio;
    final width = cardWidth + step * (cards.length - 1);
    final height = cardWidth * 1.4;
    final ownerName = ramiOwnerName(owner);
    final ownerColor = ownerName == null ? Colors.white24 : _seatColors[owner];
    const tagPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 1);
    final Color border = hot || eligible ? _goldColor : ownerColor;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hot
                  ? _goldColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 2),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  for (var i = 0; i < cards.length; i++)
                    Positioned(
                      left: step * i,
                      top: 0,
                      child: RamiCardView(card: cards[i], width: cardWidth),
                    ),
                ],
              ),
            ),
          ),
          // Étiquette posée sur le bord : ne prend aucune place dans le tapis.
          if (ownerName != null)
            Positioned(
              top: -7,
              left: 6,
              child: Container(
                padding: tagPadding,
                decoration: BoxDecoration(
                  color: ownerColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _frameColor, width: 1),
                ),
                child: Text(
                  ownerName,
                  style: const TextStyle(
                    color: _inkColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
