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
    final title = winner != null
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 7)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _goldColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      winner != null
                          ? 'PARTIE TERMINÉE'
                          : 'MANCHE ${match.round - 1}',
                      style: const TextStyle(
                        color: Color(0xFF17213D),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.contract.value} ${coincheSuitSymbol(summary.contract.mode)}$multiplier'
                    ' · ${_teamLabel[teamOf(summary.contract.seat)]}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final team in Team.values)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _teamLabel[team]!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '+${summary.awarded[team]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Cartes ${summary.points[team]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Total ${match.scores[team]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (winner != null) ...[
                    DialogButton(
                      label: t('replay'),
                      onTap: controller.restart,
                    ),
                    TextButton(
                      onPressed: onMenu,
                      child: Text(
                        t('backToMenu'),
                        style: TextStyle(color: Colors.white70),
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
        ),
      ),
    );
  }
}
