part of '../chkobba_screen.dart';

/// Taille de l'avatar inactif et de l'avatar du joueur dont c'est le tour, en dp (#728).
const double _sideAvatarSize = 30;
const double _sideAvatarActiveSize = 40;

/// Largeur d'un panneau latéral (#726) : étroit pour laisser la place au tapis sur 360 px.
const double _sidePanelWidth = 72;

/// Panneau latéral d'un joueur (#726) : avatar, score, nom et sa pile de cartes gagnées (#727).
/// Gauche = adversaire, droite = joueur. Le joueur dont c'est le tour a un médaillon agrandi (#728).
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    super.key,
    required this.game,
    required this.player,
    required this.name,
    required this.color,
    required this.avatarId,
    required this.wonKey,
    required this.wonCount,
    required this.chkobbaCards,
  });

  final ChkobbaState game;
  final Player player;
  final String name;
  final Color color;
  final String avatarId;

  /// Clé de la pile (cible de l'animation de capture).
  final Key wonKey;
  final int wonCount;
  final List<ChkobbaCard> chkobbaCards;

  @override
  Widget build(BuildContext context) {
    final finished = game.winner != null;
    final winners = game.winner == null ? <int>[] : [game.winner!.index];
    final score = game.scores[player]!;
    return SizedBox(
      width: _sidePanelWidth,
      child: Semantics(
        container: true,
        label: '$name $score',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TurnAvatar(
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
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ComicPalette.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            _WonPile(
              key: wonKey,
              count: wonCount,
              color: color,
              chkobbaCards: chkobbaCards,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tas de cartes gagnées d'un joueur, posé de son côté du tapis (#534) : adversaire en haut, moi en bas.
class _WonPile extends StatelessWidget {
  const _WonPile({
    super.key,
    required this.count,
    required this.color,
    this.chkobbaCards = const [],
  });

  final int count;
  final Color color;

  /// Cartes de Chkobba (Scoba), posées légèrement tournées sous le tas (#594, #626).
  final List<ChkobbaCard> chkobbaCards;

  /// Taille de la carte de Chkobba affichée : seule sa moitié haute est visible (#626).
  static const _cardWidth = 30.0;
  static const _cardHeight = 42.0;

  /// Décalage horizontal entre deux cartes de Chkobba, la suivante par-dessus (#626).
  static const _overlap = 7.0;

  /// Dos de carte (comme les cartes en jeu, #632) et nombre de cartes sur une
  /// étiquette encre, pour un contraste suffisant.
  @override
  Widget build(BuildContext context) {
    final pile = Container(
      width: 48,
      height: 36,
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
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ScobaPalette.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(0, 2)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: ComicPalette.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chkobbaCards.isEmpty) return pile;
    // Les Scobas sont glissées sous le tas : leur moitié haute est cachée par le tas, seule la
    // moitié basse dépasse (#649). Chaque carte suivante se pose par-dessus la précédente (#626).
    final width = _cardWidth + _overlap * (chkobbaCards.length - 1);
    const pileHeight = 36.0;
    return SizedBox(
      width: 48,
      height: pileHeight + _cardHeight / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: pileHeight - _cardHeight / 2,
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
