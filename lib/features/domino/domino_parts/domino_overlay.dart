part of '../domino_screen.dart';

/// Fait trembler son enfant quand [trigger] change (et qu'il est non nul).
class _ShakeOnTrigger extends StatelessWidget {
  const _ShakeOnTrigger({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: trigger == 0 ? 0.0 : 1.0, end: 0.0),
      duration: const Duration(milliseconds: 380),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(math.sin(v * math.pi * 4) * 8 * v, 0),
        child: child,
      ),
      child: child,
    );
  }
}

class _HandTile extends StatelessWidget {
  const _HandTile({
    required this.tile,
    required this.sm,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DominoTile tile;
  final bool sm;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: tf('sTile', {'a': '${tile.a}', 'b': '${tile.b}'}) +
          (enabled ? t('sPlayable') : t('sNotPlayable')),
      onTap: onTap,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
        child: Opacity(
          opacity: 1,
          child: DominoFace(
            first: tile.a,
            second: tile.b,
            width: sm ? 44 : 36,
            height: sm ? 88 : 68,
            highlight: selected,
          ),
        ),
      ),
    );
  }
}

class DominoRoundOverlay extends StatelessWidget {
  const DominoRoundOverlay({
    super.key,
    required this.game,
    required this.onNext,
    required this.onRestart,
    required this.onMenu,
  });

  final DominoState game;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final matchOver = game.matchWinner != null;
    final title = matchOver
        ? (game.matchWinner == Player.player ? 'Victoire !' : 'Le voisin gagne')
        : (game.roundWinner == Player.player ? 'Bien joué !' : 'On remet ça ?');
    final points = game.pointsAwarded;
    final canContinue = game.roundWinner != null && game.matchWinner == null;

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RoundResultPanel(
            title: title,
            badge: matchOver
                ? Strings.dominoMatchOver.toUpperCase()
                : 'MANCHE ${game.round} TERMINÉE',
            rows: [
              RoundResultRow(
                name: t('you'),
                color: RoundResultColors.seat(0),
                value: game.roundWinner == Player.player ? '+$points' : '0',
                total: '${game.scores[Player.player]}',
                highlight: game.roundWinner == Player.player,
              ),
              RoundResultRow(
                name: t('opponent'),
                color: RoundResultColors.seat(1),
                value: game.roundWinner == Player.opponent ? '+$points' : '0',
                total: '${game.scores[Player.opponent]}',
                highlight: game.roundWinner == Player.opponent,
              ),
            ],
            actions: [
              DialogButton(
                label: canContinue ? t('nextRound') : t('replay'),
                onTap: canContinue ? onNext : onRestart,
              ),
              TextButton(
                onPressed: onMenu,
                child: Text(
                  t('backToMenu'),
                  style: const TextStyle(color: ComicPalette.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton « Menu » du Domino en case BD (issue #97).
/// Bouton « Piocher / Passer » en case BD (#146) : rouge, contour encre, libellé en Bangers.
Widget _comicDrawChip(String label) {
  return ComicPanel(
    color: ComicPalette.red,
    radius: 8,
    shadowOffset: const Offset(3, 3),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Bangers',
        fontSize: 20,
        letterSpacing: 1,
        color: ComicPalette.paper,
      ),
    ),
  );
}
