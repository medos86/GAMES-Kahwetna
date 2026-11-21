part of '../coinche_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.difficulty});

  final CoincheController controller;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return GameHeader(
      onMenu: () => Navigator.of(context).maybePop(),
      center: Expanded(
        child: Center(
          child: Text(
            'Manche ${controller.match.round}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      trailing: TrophyBadge(
        target: controller.match.target,
        size: 48,
        tint: difficultyTint(difficulty),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau de score
// ---------------------------------------------------------------------------

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller, required this.avatarIds});

  final CoincheController controller;

  // Avatar de chaque siège, indexé par Seat (issue #554).
  final List<String> avatarIds;

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    final contract = controller.round.contract;
    final round = controller.round;
    final finished = round.phase == CoinchePhase.done;
    final winners = coincheWinnerSeats(round);
    return Semantics(
      label: tf('sScoreUsThem', {
        'a': '${match.scores[Team.ns]}',
        'b': '${match.scores[Team.ew]}',
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _frameColor, width: 3),
        ),
        child: Row(
          children: [
            _TeamScore(
              label: _teamLabel[Team.ns]!,
              score: match.scores[Team.ns]!,
              color: const Color(0xFF047857),
              avatarId: avatarIds[Seat.south.index],
              avatarState: gameAvatarState(
                seat: Seat.south.index,
                finished: finished,
                winners: winners,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'CONTRAT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17213D),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _frameColor, width: 2),
                    ),
                    child: Text(
                      contract == null
                          ? 'Enchères'
                          : '${contract.value} ${coincheSuitSymbol(contract.mode)}'
                              '${contract.multiplier > 1 ? ' ×${contract.multiplier}' : ''}'
                              ' · ${_teamLabel[teamOf(contract.seat)]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _TeamScore(
              label: _teamLabel[Team.ew]!,
              score: match.scores[Team.ew]!,
              color: const Color(0xFFB91C1C),
              avatarId: avatarIds[Seat.west.index],
              avatarState: gameAvatarState(
                seat: Seat.west.index,
                finished: finished,
                winners: winners,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.label,
    required this.score,
    required this.color,
    required this.avatarId,
    required this.avatarState,
  });

  final String label;
  final int score;
  final Color color;

  // Avatar représentant l'équipe et son état (issue #554).
  final String avatarId;
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarView(
          avatarId: avatarId,
          state: avatarState,
          size: 22,
          semanticLabel: label,
        ),
        const SizedBox(width: 4),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _inkColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tapis : sièges, pli, statut, enchères
// ---------------------------------------------------------------------------
