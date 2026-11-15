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
    this.playerWonKey,
    this.opponentWonKey,
    this.deckKey,
  });

  /// Clé de la pioche (cible de la donne animée, #238).
  final Key? deckKey;

  final ChkobbaState game;

  /// Clés des tas de cartes gagnées (cibles des captures animées, #238).
  final Key? playerWonKey;
  final Key? opponentWonKey;

  @override
  Widget build(BuildContext context) {
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
                key: playerWonKey,
                name: t('you'),
                score: game.scores[Player.player]!,
                chkobbas: game.chkobbas[Player.player]!,
                cards: game.won[Player.player]!.length,
                color: ScobaPalette.blueText,
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
                key: opponentWonKey,
                name: t('opponent'),
                score: game.scores[Player.opponent]!,
                chkobbas: game.chkobbas[Player.opponent]!,
                cards: game.won[Player.opponent]!.length,
                color: ScobaPalette.redText,
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
    super.key,
    required this.name,
    required this.score,
    required this.chkobbas,
    required this.cards,
    required this.color,
  });

  final String name;
  final int score;
  final int chkobbas;
  final int cards;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const info = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: ScobaPalette.ink,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              const SizedBox(width: 8),
              Text(tf('cardCount', {'n': '$cards'}), style: info),
            ],
          ),
        ),
      ],
    );
  }
}
