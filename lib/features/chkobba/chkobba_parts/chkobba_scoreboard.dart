part of '../chkobba_screen.dart';

/// Pastille du score cible (trophée jaune avec le nombre dessus).
class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.target});

  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 44, color: Color(0xFFFBBF24)),
          Align(
            alignment: const Alignment(0, -0.25),
            child: Text(
              '$target',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF20284B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tableau de bord : score de chaque joueur, Chkobba, cartes ramassées et pioche.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.game,
    required this.avatarIds,
    this.deckKey,
  });

  /// Clé de la pioche (cible de la donne animée, #238).
  final Key? deckKey;

  final ChkobbaState game;

  /// Avatars [joueur, adversaire] (issue #551).
  final List<String> avatarIds;

  @override
  Widget build(BuildContext context) {
    final finished = game.winner != null;
    final winners = game.winner == null ? <int>[] : [game.winner!.index];
    return Semantics(
      container: true,
      label: tf('sChkScore', {
        'a': '${game.scores[Player.player]}',
        'b': '${game.scores[Player.opponent]}',
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: _ScoreSide(
                name: t('you'),
                score: game.scores[Player.player]!,
                chkobbas: game.chkobbas[Player.player]!,
                color: ScobaPalette.blueText,
                avatarId: avatarIds[Player.player.index],
                avatarState: gameAvatarState(
                  seat: Player.player.index,
                  finished: finished,
                  winners: winners,
                ),
              ),
            ),
            Semantics(
              label: tf('sDeckLeft', {'n': '${game.deck.length}'}),
              child: KeyedSubtree(
                key: deckKey,
                child: _DeckPile(count: game.deck.length),
              ),
            ),
            Flexible(
              child: _ScoreSide(
                name: t('opponent'),
                score: game.scores[Player.opponent]!,
                chkobbas: game.chkobbas[Player.opponent]!,
                color: ScobaPalette.redText,
                avatarId: avatarIds[Player.opponent.index],
                avatarState: gameAvatarState(
                  seat: Player.opponent.index,
                  finished: finished,
                  winners: winners,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSide extends StatelessWidget {
  const _ScoreSide({
    required this.name,
    required this.score,
    required this.chkobbas,
    required this.color,
    required this.avatarId,
    required this.avatarState,
  });

  final String name;
  final int score;
  final int chkobbas;
  final Color color;

  /// Avatar du joueur et son état (issue #551).
  final String avatarId;
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    const info = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: ScobaPalette.ink,
    );
    // L'avatar est à côté du score, et non au-dessus : la hauteur du tableau ne change pas (#627).
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarView(
              avatarId: avatarId,
              state: avatarState,
              size: 30,
              semanticLabel: name,
            ),
            const SizedBox(width: 3),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
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
          ],
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 12, color: ScobaPalette.blueText),
              Text(' $chkobbas', style: info),
            ],
          ),
        ),
      ],
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
                  color: ComicPalette.ink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: ComicPalette.white,
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
    // Une Scoba par carte : chaque carte suivante se pose par-dessus la précédente, décalée
    // d'un peu, pour que les deux restent visibles (#626). Seule la moitié haute est montrée.
    final width = _cardWidth + _overlap * (chkobbaCards.length - 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pile,
        const SizedBox(height: 4),
        Transform.rotate(
          angle: 0.12,
          child: ClipRect(
            child: SizedBox(
              width: width,
              height: _cardHeight / 2,
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
      ],
    );
  }
}
