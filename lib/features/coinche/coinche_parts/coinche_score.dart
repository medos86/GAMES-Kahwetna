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
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'Manche ${controller.match.round}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                DifficultyChip(difficulty: difficulty),
              ],
            ),
          ],
        ),
      ),
      trailing: Semantics(
        label: tf('sMatchTarget', {'n': '${controller.match.target}'}),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 48,
                color: Color(0xFFFBBF24),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${controller.match.target}',
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau de score
// ---------------------------------------------------------------------------

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller});

  final CoincheController controller;

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    final contract = controller.round.contract;
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
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
