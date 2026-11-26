part of '../coinche_screen.dart';

class _HandFooter extends StatelessWidget {
  const _HandFooter({
    required this.controller,
    required this.cardWidth,
    required this.keyOf,
    required this.landing,
    required this.name,
  });

  final CoincheController controller;
  final double cardWidth;
  final GlobalKey Function(String name) keyOf;
  final Set<String> landing;

  // Pseudo du joueur (#838) ; son avatar est dans le coin de son équipe (#1004).
  final String name;

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
          trump: coincheIsTrump(card, controller.round.contract),
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

    final round = controller.round;
    final active = round.turn == Seat.south &&
        (round.phase == CoinchePhase.bidding ||
            round.phase == CoinchePhase.playing);

    // Main posée dans le grand tapis (#838) : pas de cadre ni de fond propres.
    return Container(
      key: keyOf('seat:south'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? _goldColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _frameColor, width: 2),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TA MAIN · ${hand.length} cartes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              if (contract != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _frameColor, width: 2),
                  ),
                  child: Text(
                    'Atout : ${coincheSuitSymbol(contract.mode)}',
                    style: TextStyle(
                      color: coincheSuitColor(contract.mode),
                      fontWeight: FontWeight.w900,
                    ),
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
  const _SummaryDialog({
    required this.controller,
    required this.onMenu,
    this.avatarIds = const [],
    this.revealed,
  });

  /// Issue #932 : animation de fin montée après la pub.
  final ValueListenable<bool>? revealed;

  final CoincheController controller;
  final VoidCallback onMenu;

  /// Avatar de chaque siège, indexé par Seat (#628). Une équipe prend l'avatar de son représentant
  /// (sud pour NS, ouest pour EW), comme dans le tableau de score.
  final List<String> avatarIds;

  String? _teamAvatar(Team team) {
    final seat = team == Team.ns ? Seat.south.index : Seat.west.index;
    return seat < avatarIds.length ? avatarIds[seat] : null;
  }

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
    final suit = coincheSuitSymbol(summary.contract.mode);
    final contract = '${summary.contract.value} $suit$multiplier';
    final contractTeam = teamOf(summary.contract.seat);
    final subtitle = '$contract · ${_teamLabel[contractTeam]}';
    // Manche gagnée : équipe du contrat si réussi, l'autre sinon (#526).
    final roundWinner = summary.made
        ? contractTeam
        : Team.values.firstWhere((other) => other != contractTeam);

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RoundResultPanel(
            title: title,
            badge: ended ? 'PARTIE TERMINÉE' : 'MANCHE ${match.round - 1}',
            subtitle: subtitle,
            won: ended ? roundWinner == teamOf(Seat.south) : null,
            revealed: revealed,
            rows: [
              for (final team in Team.values)
                RoundResultRow(
                  name: _teamLabel[team]!,
                  color: RoundResultColors.seat(team.index),
                  avatarId: _teamAvatar(team),
                  value: '+${summary.awarded[team]}',
                  reason: 'Cartes ${summary.points[team]}',
                  total: '${match.scores[team]}',
                  highlight: team == roundWinner,
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
