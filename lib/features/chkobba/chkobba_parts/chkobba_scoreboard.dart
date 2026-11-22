part of '../chkobba_screen.dart';

/// Taille de l'avatar inactif et de l'avatar du joueur dont c'est le tour, en dp (#728, #766).
const double _sideAvatarSize = 26;
const double _sideAvatarActiveSize = 32;

/// Écriture BD (score, nom) : Bangers, contour encre et ombre portée (#766).
/// Un seul widget Text, pour que le score reste lisible par un seul texte.
TextStyle _comicText({required double size, required Color fill}) {
  return TextStyle(
    fontFamily: 'Bangers',
    fontSize: size,
    height: 1.0,
    letterSpacing: 0.5,
    color: fill,
    shadows: const [
      Shadow(color: Colors.black, offset: Offset(-1.5, -1.5)),
      Shadow(color: Colors.black, offset: Offset(1.5, -1.5)),
      Shadow(color: Colors.black, offset: Offset(-1.5, 1.5)),
      Shadow(color: Colors.black, offset: Offset(1.5, 1.5)),
      Shadow(color: Colors.black, offset: Offset(0, 3)),
    ],
  );
}

/// Coin d'un joueur (#766, #800) : avatar et score en autocollant BD, nom en Bangers.
/// La pile gagnée et la pioche sont dans l'autre coin de la même rangée (voir `_SeatRow`).
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    super.key,
    required this.game,
    required this.player,
    required this.name,
    required this.color,
    required this.avatarId,
    required this.opponentSide,
    this.reaction,
  });

  final ChkobbaState game;
  final Player player;
  final String name;
  final Color color;
  final String avatarId;

  /// Vrai pour l'adversaire : score côté tapis, avatar à l'extérieur (#800).
  final bool opponentSide;

  /// Sticker BD près de l'avatar (#761), ou null.
  final ReactionMood? reaction;

  @override
  Widget build(BuildContext context) {
    final finished = game.winner != null;
    final winners = game.winner == null ? <int>[] : [game.winner!.index];
    final score = game.scores[player]!;
    final avatar = TurnAvatar(
      tone: color,
      active: game.winner == null && game.turn == player,
      avatarId: avatarId,
      state: gameAvatarState(
        seat: player.index,
        finished: finished,
        winners: winners,
      ),
      semanticLabel: name,
      baseSize: _sideAvatarSize,
      activeSize: _sideAvatarActiveSize,
    );
    // Sticker de réaction posé à côté de l'avatar, sans décaler la mise en page (#761).
    final avatarSlot = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          // Adversaire à droite : le sticker part vers l'intérieur du tapis.
          left: opponentSide ? -44 : null,
          right: opponentSide ? null : -44,
          top: -30,
          child: ReactionSticker(
            mood: reaction,
            size: 58,
            semanticLabel: name,
          ),
        ),
      ],
    );
    // Adversaire : score puis avatar à droite. Joueur : avatar puis score.
    final identityChildren = [
      avatarSlot,
      const SizedBox(width: 4),
      _ScoreSticker(score: score, color: color),
    ];
    // Mise à l'échelle si le coin est étroit : avatar et score ne débordent jamais.
    final identity = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: opponentSide
            ? identityChildren.reversed.toList()
            : identityChildren,
      ),
    );
    final nameLabel = Text(
      name.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _comicText(size: 15, fill: ComicPalette.white),
    );
    // Avatar, score et pseudo groupés dans un même encadré BD (lisible sur le feutre).
    final box = Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        color: ComicPalette.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [identity, const SizedBox(height: 2), nameLabel],
      ),
    );
    return Semantics(
      container: true,
      label: '$name $score',
      child: box,
    );
  }
}

/// Score en autocollant BD (#766) : chiffre Bangers blanc, contour encre, léger penché.
class _ScoreSticker extends StatelessWidget {
  const _ScoreSticker({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3)),
          ],
        ),
        child: Text('$score', style: _comicText(size: 22, fill: Colors.white)),
      ),
    );
  }
}

/// Tas de cartes gagnées d'un joueur, posé de son côté du tapis (#534, #766). Sans compteur.
class _WonPile extends StatelessWidget {
  const _WonPile({
    super.key,
    required this.color,
    this.chkobbaCards = const [],
  });

  final Color color;

  /// Cartes de Chkobba (Scoba), posées légèrement tournées sous le tas (#594, #626).
  final List<ChkobbaCard> chkobbaCards;

  /// Dimensions du tas et de la carte de Chkobba affichée : seule sa moitié haute est visible (#626).
  static const _pileWidth = 56.0;
  static const _pileHeight = 44.0;
  static const _cardWidth = 36.0;
  static const _cardHeight = 50.0;

  /// Décalage horizontal entre deux cartes de Chkobba, la suivante par-dessus (#626).
  static const _overlap = 8.0;

  /// Dos de carte, comme les cartes en jeu (#632). Pas de compteur de cartes.
  @override
  Widget build(BuildContext context) {
    final pile = Container(
      width: _pileWidth,
      height: _pileHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ChkobbaCardBack(),
          ],
        ),
      ),
    );
    if (chkobbaCards.isEmpty) return pile;
    // Les Scobas sont glissées sous le tas : leur moitié haute est cachée par le tas, seule la
    // moitié basse dépasse (#649). Chaque carte suivante se pose par-dessus la précédente (#626).
    final width = _cardWidth + _overlap * (chkobbaCards.length - 1);
    return SizedBox(
      width: _pileWidth,
      height: _pileHeight + _cardHeight / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: _pileHeight - _cardHeight / 2,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: 0.12,
                child: SizedBox(
                  width: width,
                  height: _cardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < chkobbaCards.length; i++)
                        Positioned(
                          left: i * _overlap,
                          top: 0,
                          width: _cardWidth,
                          height: _cardHeight,
                          child: ChkobbaCardFace(
                            key: ValueKey('scoba:${chkobbaCards[i].id}'),
                            card: chkobbaCards[i],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, child: pile),
        ],
      ),
    );
  }
}
