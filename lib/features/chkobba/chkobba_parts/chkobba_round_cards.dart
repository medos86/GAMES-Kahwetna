part of '../chkobba_screen.dart';

/// Résultat final de la partie (affiché sur le tapis après le récapitulatif).
class _FinalCard extends StatelessWidget {
  const _FinalCard({required this.state});

  final ChkobbaState state;

  @override
  Widget build(BuildContext context) {
    final won = state.winner == Player.player;
    final rounds = state.round;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? '🏆 Victoire !' : 'Défaite',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${state.scores[Player.player]} – ${state.scores[Player.opponent]} · $rounds manche${rounds > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Récapitulatif de manche, comme la carte « Manche N » du source.
class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.summary, required this.onContinue});

  final ChkobbaRoundScore summary;
  final VoidCallback onContinue;

  // La correspondance porte sur le libellé français produit par la logique du jeu (inchangé).
  // Seul l'affichage est traduit, avec une clé lue à chaque build (pas de cache de langue).
  static final _categories = <({String key, bool Function(String) matches})>[
    (key: 'catChkobba', matches: (l) => l.startsWith('Chkobba')),
    (key: 'catHaya', matches: (l) => l.startsWith('Haya')),
    (key: 'catCards', matches: (l) => l == 'Cartes'),
    (key: 'catDeniers', matches: (l) => l == 'Deniers'),
    (key: 'catBermila', matches: (l) => l == 'Bermila'),
  ];

  int _pointsFor(Player p, bool Function(String) matches) => summary.points[p]!
      .where((x) => matches(x.label))
      .fold(0, (sum, x) => sum + x.value);

  int _total(Player p) => summary.points[p]!.fold(0, (sum, x) => sum + x.value);

  static String _show(int v) => v == 0 ? '—' : '$v';

  Widget _row(
    String label,
    String player,
    String opponent, {
    TextStyle? style,
    double pad = 8,
  }) {
    final base = style ??
        const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: ScobaPalette.ink,
        );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: pad),
      child: Row(
        children: [
          Expanded(child: Text(label, style: base)),
          SizedBox(
            width: 64,
            child: Text(
              player,
              textAlign: TextAlign.center,
              style: base.copyWith(color: ScobaPalette.blueText),
            ),
          ),
          SizedBox(
            width: 76,
            child: Text(
              opponent,
              textAlign: TextAlign.center,
              style: base.copyWith(color: ScobaPalette.redText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = summary.state;
    final winner = state.winner;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: ScobaPalette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 7))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ScobaPalette.felt, ScobaPalette.feltDeep],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 4),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE16B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      'RÉCAPITULATIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: ScobaPalette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manche ${state.round}',
                    style: const TextStyle(
                      color: ScobaPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row(
                    t('roundPoints'),
                    t('you'),
                    t('opponent'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: ScobaPalette.ink,
                    ),
                    pad: 0,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _categories.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(
                                      top: BorderSide(
                                        color: ScobaPalette.ink,
                                        width: 2,
                                      ),
                                    ),
                            ),
                            child: _row(
                              t(_categories[i].key),
                              _show(
                                _pointsFor(
                                  Player.player,
                                  _categories[i].matches,
                                ),
                              ),
                              _show(
                                _pointsFor(
                                  Player.opponent,
                                  _categories[i].matches,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: ScobaPalette.felt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _row(
                      'Score de la manche',
                      '+${_total(Player.player)}',
                      '+${_total(Player.opponent)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: ScobaPalette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE16B), Color(0xFFFFC24B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _row(
                      'Score total',
                      '${state.scores[Player.player]}',
                      '${state.scores[Player.opponent]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: ScobaPalette.ink,
                      ),
                      pad: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE16B), Color(0xFFFFB43C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Text(
                        winner == null
                            ? 'Manche suivante →'
                            : 'Voir le résultat final',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: ScobaPalette.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de choix quand une carte peut prendre plusieurs combinaisons (« Que veux-tu prendre ? »).
class _CapturePicker extends StatelessWidget {
  const _CapturePicker({required this.options});

  final List<List<ChkobbaCard>> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ScobaPalette.felt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.black, width: 4)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Que veux-tu prendre ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ScobaPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final card in option)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: SizedBox(
                                width: 52,
                                height: 74,
                                child: ChkobbaCardFace(card: card),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScobaPalette.ink,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Strings.actCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
