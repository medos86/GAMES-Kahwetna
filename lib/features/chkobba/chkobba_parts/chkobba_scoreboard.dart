part of '../chkobba_screen.dart';

/// Taille de l'avatar inactif et de l'avatar du joueur dont c'est le tour, en dp.
/// Mêmes tailles que les médaillons de la Belote (`_SeatInfo`).
const double _sideAvatarSize = 28;
const double _sideAvatarActiveSize = 40;

/// Coin d'un joueur, mis en page comme à la Belote (`_SeatInfo`) : avatar, pastille du pseudo,
/// puis pastille du score (même style que le score de la Belote). La pile gagnée et la pioche
/// sont dans l'autre coin de la même rangée (voir `_SeatRow`).
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

  /// Vrai pour l'adversaire : le sticker de réaction part vers l'intérieur du tapis.
  final bool opponentSide;

  /// Sticker BD près de l'avatar (#761), ou null.
  final ReactionMood? reaction;

  @override
  Widget build(BuildContext context) {
    final finished = game.winner != null;
    final winners = game.winner == null ? <int>[] : [game.winner!.index];
    final score = game.scores[player]!;
    final active = game.winner == null && game.turn == player;
    final avatar = TurnAvatar(
      tone: color,
      active: active,
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
    // Emplacement de taille fixe (#954) : l'avatar actif grossit sans faire bouger le tapis.
    final avatarSlot = SizedBox(
      width: _sideAvatarActiveSize,
      height: _sideAvatarActiveSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Align(child: avatar),
          Positioned(
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
      ),
    );
    return Semantics(
      container: true,
      label: '$name $score',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatarSlot,
          const SizedBox(height: 2),
          _NamePill(name: name, active: active),
          const SizedBox(height: 4),
          _ScorePill(score: score, color: color),
        ],
      ),
    );
  }
}

/// Pastille du pseudo, comme la Belote : dorée quand c'est son tour, sombre sinon.
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

/// Pastille du score, comme le score d'équipe de la Belote : fond blanc, chiffre à la couleur du joueur.
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
