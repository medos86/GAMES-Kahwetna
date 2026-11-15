part of '../ludo_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final turnName = _colorName(game.turn, solo);
    final prompt = controller.roundOver
        ? ''
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
  });

  final int? value;
  final Color tone;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final face = value ?? 5;
    final pips = _pipLayout[face]!;
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

class _EndDialog extends StatelessWidget {
  const _EndDialog({required this.controller, required this.onMenu});

  final LudoController controller;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final first = game.rankings.first;
    final title = solo && first == LudoColor.blue
        ? 'Victoire !'
        : '${_colorName(first, solo)} gagne';

    return ColoredBox(
      color: const Color(0xB3052A52),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3F7A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFD653), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Color(0xFFFFD653),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PARTIE TERMINÉE',
                    style: TextStyle(
                      color: Color(0xFFFFD653),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < game.rankings.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: _toneOf(game.rankings[i]).fill,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _colorName(game.rankings[i], solo),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE17B),
                        foregroundColor: const Color(0xFF3D351F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: controller.restart,
                      child: Text(
                        t('replay'),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onMenu,
                    child: Text(
                      t('backToMenu'),
                      style: TextStyle(color: Colors.white60),
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
