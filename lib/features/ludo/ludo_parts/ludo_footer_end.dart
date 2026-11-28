part of '../ludo_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final turnName = _colorName(controller.shownTurn, solo);
    final prompt = controller.roundOver
        ? ''
        : controller.refusedColor != null
            ? t('sLudoNoMove')
            : game.note != null
                ? _noteText(game.note!, solo)
                : controller.humanTurn
                    ? game.phase == LudoPhase.roll
                        ? '${solo ? 'À toi' : 'À $turnName'} : lance le dé'
                        : 'Touche un pion en surbrillance'
                    : '$turnName joue…';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brown, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOUR : ${turnName.toUpperCase()}',
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dé : tourne et rebondit à chaque lancer (le widget est recréé pour chaque rollId).
/// `animate` est vrai seulement pour le dé du joueur qui vient de lancer (#120) :
/// les dés inactifs restent immobiles.
class LudoDie extends StatelessWidget {
  const LudoDie({
    super.key,
    required this.value,
    required this.tone,
    this.size = 56,
    this.animate = true,
    this.refused = false,
  });

  final int? value;
  final Color tone;
  final double size;
  final bool animate;

  /// Lancer sans coup possible : le dé secoue la tête « non » (#855).
  final bool refused;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (refused) {
      // Lancer bloquant (#1080) : le dé roule d'abord, puis secoue la tête pour dire « non ».
      if (animate && value != null && !reduceMotion) {
        return _RefusedRoll(value: value, tone: tone, size: size);
      }
      // Le dé garde sa face et secoue la tête pour dire « non », sans mot affiché (#883 / #855).
      return _HeadShake(
        child: LudoDie(value: value, tone: tone, size: size, animate: false),
      );
    }
    final rolled = value;
    if (animate && rolled != null && !reduceMotion) {
      // Lancer en 3D : le cube roule et se pose sur la valeur tirée (#998).
      return Semantics(
        label: tf('sDieValue', {'v': '$rolled'}),
        child: ExcludeSemantics(
          child: _LudoDieTumble(value: rolled, tone: tone, size: size),
        ),
      );
    }
    final face = value ?? 5;
    final pips = ludoPipIndexes(face);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final still = reduce || !animate;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.rotate(
        angle: (1 - t) * -200 * math.pi / 180,
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Semantics(
        label: value != null ? tf('sDieValue', {'v': '$value'}) : t('sDie'),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E9),
            borderRadius: BorderRadius.circular(size * 0.21),
            border: Border.all(color: const Color(0xFF24364B), width: 3),
          ),
          child: Stack(
            children: [
              for (final index in pips)
                Align(
                  alignment: Alignment(
                    _pipAxis[index % 3] / 50 - 1,
                    _pipAxis[index ~/ 3] / 50 - 1,
                  ),
                  child: Opacity(
                    opacity: value != null ? 1 : 0.2,
                    child: Container(
                      width: size * 0.21,
                      height: size * 0.21,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF24364B),
                          width: 1.5,
                        ),
                      ),
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

/// Lancer bloquant (#1080) : le cube roule pendant [kLudoDieRollDuration],
/// puis il secoue la tête « non » sur la face tirée.
class _RefusedRoll extends StatefulWidget {
  const _RefusedRoll({
    required this.value,
    required this.tone,
    required this.size,
  });

  final int value;
  final Color tone;
  final double size;

  @override
  State<_RefusedRoll> createState() => _RefusedRollState();
}

class _RefusedRollState extends State<_RefusedRoll> {
  bool _tumbling = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kLudoDieRollDuration, () {
      if (mounted) setState(() => _tumbling = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tumbling) {
      return Semantics(
        label: tf('sDieValue', {'v': '${widget.value}'}),
        child: ExcludeSemantics(
          child: _LudoDieTumble(
            value: widget.value,
            tone: widget.tone,
            size: widget.size,
          ),
        ),
      );
    }
    return _HeadShake(
      child: LudoDie(
        value: widget.value,
        tone: widget.tone,
        size: widget.size,
        animate: false,
      ),
    );
  }
}

/// Secousse horizontale de la tête du dé pour dire « non » (#855).
/// Sans animation si l'utilisateur a réduit les animations.
class _HeadShake extends StatelessWidget {
  const _HeadShake({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, progress, child) {
        // Trois allers-retours qui s'amortissent.
        final dx = math.sin(progress * math.pi * 6) * 9 * (1 - progress);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}

/// Couleur du chiffre de classement sur la pastille d'un joueur (#295).
/// Prend l'encre ou le blanc, selon celui qui contraste le plus avec le fond :
/// le texte reste lisible sur les quatre couleurs (contraste >= 4,5).
Color ludoRankDigitColor(Color fill) {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  return contrast(ComicPalette.ink, fill) >= contrast(Colors.white, fill)
      ? ComicPalette.ink
      : Colors.white;
}

/// Rang affiché à droite de la ligne de fin : « 1er », « 2e »… (issue #526).
String _placeLabel(int index) => index == 0 ? '1er' : '${index + 1}e';

class _EndDialog extends StatelessWidget {
  const _EndDialog({
    required this.controller,
    required this.onMenu,
    this.revealed,
  });

  final LudoController controller;
  final VoidCallback onMenu;

  /// Issue #932 : animation de fin montée après la pub.
  final ValueListenable<bool>? revealed;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final first = game.rankings.first;
    final title = solo && first == LudoColor.blue
        ? 'Victoire !'
        : '${_colorName(first, solo)} gagne';

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RoundResultPanel(
            title: title,
            badge: 'PARTIE TERMINÉE',
            won: solo ? first == LudoColor.blue : null,
            revealed: revealed,
            rows: [
              for (var i = 0; i < game.rankings.length; i++)
                RoundResultRow(
                  name: _colorName(game.rankings[i], solo),
                  color: _toneOf(game.rankings[i]).fill,
                  leading: '${i + 1}',
                  value: _placeLabel(i),
                  highlight: i == 0,
                ),
            ],
            actions: [
              DialogButton(label: t('replay'), onTap: controller.restart),
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

/// Tous les humains sont arrivés : finir la partie ou voir la fin (#387).
/// Couleurs du thème Ludo (_ink, _cream, _brown) : aucune couleur en dur ici.
class _ChoiceDialog extends StatelessWidget {
  const _ChoiceDialog({required this.onFinish, required this.onShowEnd});

  final VoidCallback onFinish;
  final VoidCallback onShowEnd;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ink.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _brown, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tous tes pions sont arrivés !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Finir la partie avec les autres, ou voir la fin ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _brown),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: _cream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onFinish,
                      child: const Text(
                        'Finir la partie',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onShowEnd,
                    child: const Text(
                      'Voir la fin',
                      style: TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
