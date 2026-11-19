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
    this.deckKey,
  });

  /// Clé de la pioche (cible de la donne animée, #238).
  final Key? deckKey;

  final ChkobbaState game;

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
                name: t('you'),
                score: game.scores[Player.player]!,
                chkobbas: game.chkobbas[Player.player]!,
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
                name: t('opponent'),
                score: game.scores[Player.opponent]!,
                chkobbas: game.chkobbas[Player.opponent]!,
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
    required this.name,
    required this.score,
    required this.chkobbas,
    required this.color,
  });

  final String name;
  final int score;
  final int chkobbas;
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
            ],
          ),
        ),
      ],
    );
  }
}

/// Tas de cartes gagnées d'un joueur, posé de son côté du tapis (#534) : adversaire en haut, moi en bas.
class _WonPile extends StatelessWidget {
  const _WonPile({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  /// Seulement le nombre de cartes, sur le décor bois de Chkobba (#593).
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _WoodBackground(),
            Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
