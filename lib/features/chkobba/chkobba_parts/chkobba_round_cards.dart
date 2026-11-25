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
    this.avatarIds = const [],
    this.revealed,
  });

  final ChkobbaRoundScore summary;
  final VoidCallback onContinue;

  /// Issue #932 : animation de fin montée après la pub.
  final ValueListenable<bool>? revealed;

  /// Avatars [joueur, adversaire] (#628) : dans les pastilles, à la place des initiales.
  final List<String> avatarIds;

  String? _avatarAt(int index) =>
      index < avatarIds.length ? avatarIds[index] : null;

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

  /// Motif d'une ligne : catégories qui rapportent des points, ex. « Chkobba 1 · Cartes 2 ».
  String? _reasonFor(Player p) {
    final parts = <String>[
      for (final c in _categories)
        if (_pointsFor(p, c.matches) != 0)
          '${t(c.key)} ${_pointsFor(p, c.matches)}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Une ligne par joueur, même format que les autres jeux (issue #526).
  @override
  Widget build(BuildContext context) {
    final state = summary.state;
    final hasWinner = state.winner != null;
    final roundYou = _total(Player.player);
    final roundOpp = _total(Player.opponent);
    return RoundResultPanel(
      title: 'Manche ${state.round}',
      badge: 'OBJECTIF ${state.targetScore} POINTS',
      won: hasWinner ? state.winner == Player.player : null,
      revealed: revealed,
      rows: [
        RoundResultRow(
          name: t('you'),
          color: RoundResultColors.seat(0),
          avatarId: _avatarAt(0),
          value: '+$roundYou',
          reason: _reasonFor(Player.player),
          total: '${state.scores[Player.player]}',
          highlight: roundYou > roundOpp,
        ),
        RoundResultRow(
          name: t('opponent'),
          color: RoundResultColors.seat(1),
          avatarId: _avatarAt(1),
          value: '+$roundOpp',
          reason: _reasonFor(Player.opponent),
          total: '${state.scores[Player.opponent]}',
          highlight: roundOpp > roundYou,
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
