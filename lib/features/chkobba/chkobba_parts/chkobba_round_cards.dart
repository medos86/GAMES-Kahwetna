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

/// Récapitulatif de manche Chkobba en style BD, via [ResultDialog] (issue #295).
/// Seul le contenu (points par catégorie, totaux, action) est propre à Chkobba.
class ChkobbaRoundCard extends StatelessWidget {
  const ChkobbaRoundCard({
    super.key,
    required this.summary,
    required this.onContinue,
  });

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

  /// Une ligne du tableau : libellé, points du joueur, points de l'adversaire.
  /// Texte en encre noire sur papier (contraste ≥ 4,5), sans couleur de joueur.
  Widget _row(
    String label,
    String player,
    String opponent, {
    bool strong = false,
    double size = 14,
  }) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      fontSize: size,
      color: ComicPalette.ink,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          SizedBox(
            width: 64,
            child: Text(player, textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: 76,
            child: Text(opponent, textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = summary.state;
    final hasWinner = state.winner != null;
    return ResultDialog(
      title: 'Manche ${state.round}',
      children: [
        _row(t('roundPoints'), t('you'), t('opponent'), strong: true),
        for (final category in _categories)
          _row(
            t(category.key),
            _show(_pointsFor(Player.player, category.matches)),
            _show(_pointsFor(Player.opponent, category.matches)),
          ),
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: ComicPalette.ink,
        ),
        _row(
          'Score de la manche',
          '+${_total(Player.player)}',
          '+${_total(Player.opponent)}',
          strong: true,
        ),
        _row(
          'Score total',
          '${state.scores[Player.player]}',
          '${state.scores[Player.opponent]}',
          strong: true,
          size: 18,
        ),
        Text(
          'Objectif : ${state.targetScore} points',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: ComicPalette.ink,
          ),
        ),
      ],
      actions: [
        _ComicButton(
          label: hasWinner ? 'Voir le résultat final' : 'Manche suivante →',
          onTap: onContinue,
        ),
      ],
    );
  }
}

/// Bouton d'action en style BD : fond or, contour encre, ombre portée.
class _ComicButton extends StatelessWidget {
  const _ComicButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ComicPalette.gold,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ComicPalette.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: ComicPalette.ink, offset: Offset(0, 5)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: ComicPalette.ink,
            ),
          ),
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
