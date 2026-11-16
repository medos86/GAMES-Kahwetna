part of '../coinche_screen.dart';

class _HandFooter extends StatelessWidget {
  const _HandFooter({
    required this.controller,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
  });

  final CoincheController controller;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  /// Une carte de la main : elle reste vide tant qu'elle vole vers la main.
  Widget _handCard(CoincheCard card, Set<String> legal, bool dimmed) {
    final playable = legal.contains(card.id);
    void play() => controller.playHuman(card.id);
    return KeyedSubtree(
      key: keyOf('hand:${card.id}'),
      child: MaskedSlot(
        hidden: landing.contains(card.id),
        child: CoincheCardView(
          width: cardWidth,
          card: card,
          dimmed: dimmed && !playable,
          onTap: dimmed && playable ? play : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hand = controller.hand;
    final contract = controller.round.contract;
    final legal = controller.legalIds;
    final dimmed = controller.isHumanPlayTurn;

    return Container(
      key: keyOf('seat:south'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TA MAIN · ${hand.length} cartes',
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              if (contract != null)
                Text(
                  'Atout : ${coincheSuitSymbol(contract.mode)}',
                  style: TextStyle(
                    color: coincheSuitColor(contract.mode),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final n = hand.length;
              if (n == 0) return SizedBox(height: cardWidth * 1.4 + 12);
              // Chevauchement de 65 % de la largeur, réduit si la main ne tient pas.
              final overlap =
                  n > 1 ? (constraints.maxWidth - cardWidth) / (n - 1) : 0.0;
              final step = [
                cardWidth * 0.65,
                overlap,
              ].reduce((a, b) => a < b ? a : b);
              final total = cardWidth + step * (n - 1);
              return SizedBox(
                height: cardWidth * 1.4 + 12,
                child: Center(
                  child: SizedBox(
                    width: total,
                    child: Stack(
                      children: [
                        for (var i = 0; i < n; i++)
                          Positioned(
                            left: step * i,
                            top: legal.contains(hand[i].id) && dimmed ? 0 : 8,
                            child: _handCard(hand[i], legal, dimmed),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Récapitulatif de manche ou de partie
// ---------------------------------------------------------------------------

class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({required this.controller, required this.onMenu});

  final CoincheController controller;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary!;
    final match = controller.match;
    final winner = match.winner;
    final ended = winner != null;
    final title = ended
        ? (winner == Team.ns ? 'Victoire !' : 'Défaite')
        : summary.made
            ? (summary.capot ? 'Capot !' : 'Contrat réussi')
            : 'Chute';
    final multiplier = summary.contract.multiplier > 1
        ? ' ×${summary.contract.multiplier}'
        : '';

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ResultDialog(
            title: title,
            children: [
              Text(
                ended ? 'PARTIE TERMINÉE' : 'MANCHE ${match.round - 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ComicPalette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.contract.value} ${coincheSuitSymbol(summary.contract.mode)}$multiplier'
                ' · ${_teamLabel[teamOf(summary.contract.seat)]}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ComicPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final team in Team.values)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ComicPalette.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ComicPalette.ink, width: 3),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _teamLabel[team]!.toUpperCase(),
                              style: const TextStyle(
                                color: ComicPalette.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '+${summary.awarded[team]}',
                              style: const TextStyle(
                                color: ComicPalette.ink,
                                fontFamily: 'Bangers',
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'Cartes ${summary.points[team]}',
                              style: const TextStyle(
                                color: ComicPalette.ink,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Total ${match.scores[team]}',
                              style: const TextStyle(
                                color: ComicPalette.ink,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            actions: [
              if (ended) ...[
                DialogButton(
                  label: t('replay'),
                  onTap: controller.restart,
                ),
                TextButton(
                  onPressed: onMenu,
                  child: Text(
                    t('backToMenu'),
                    style: const TextStyle(color: ComicPalette.ink),
                  ),
                ),
              ] else
                DialogButton(
                  label: t('nextRound'),
                  onTap: controller.nextRound,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
