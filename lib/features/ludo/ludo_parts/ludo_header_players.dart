part of '../ludo_screen.dart';

/// Avatar de chaque couleur (issue #553) : le joueur humain (premier de
/// [ludoHumanOrder]) garde son profil, les autres reçoivent les avatars IA.
Map<LudoColor, String> ludoAvatarByColor(List<String> ids) {
  final human = ludoHumanOrder.first;
  final result = <LudoColor, String>{};
  var next = 1;
  for (final color in LudoColor.values) {
    result[color] = color == human ? ids.first : ids[next++];
  }
  return result;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.difficulty,
    required this.avatarIds,
  });

  final LudoController controller;
  final Difficulty difficulty;

  /// Avatar par couleur (issue #553).
  final Map<LudoColor, String> avatarIds;

  // Vainqueur de la partie : premier du classement, seulement une fois finie.
  List<int> _winners() {
    final rankings = controller.game.rankings;
    if (rankings.isEmpty) return const [];
    return [rankings.first.index];
  }

  @override
  Widget build(BuildContext context) {
    final count = controller.playerCount;
    final finished = controller.roundOver;
    final winners = _winners();
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
                for (final color in LudoColor.values)
                  AvatarView(
                    avatarId: avatarIds[color] ?? defaultAvatar.id,
                    state: gameAvatarState(
                      seat: color.index,
                      finished: finished,
                      winners: winners,
                    ),
                    size: 24,
                    semanticLabel: _colorName(color, controller.solo),
                  ),
                Text(
                  count == 1
                      ? t('ludoPlayerOne')
                      : tf('ludoPlayers', {'n': '$count'}),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                DifficultyChip(difficulty: difficulty),
              ],
            ),
          ],
        ),
      ),
      // Équilibre la pastille Menu : le centre reste au milieu de l'écran.
      trailing: const SizedBox(width: 48),
    );
  }
}

/// Taille du dé affiché sur la carte d'un joueur.
const _dieSize = 34.0;

/// Une rangée de deux cartes joueurs. La rangée du haut (rouge, vert) est retournée à 180°.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.controller, required this.top});

  final LudoController controller;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final colors = top
        ? const [LudoColor.red, LudoColor.green]
        : const [LudoColor.blue, LudoColor.yellow];
    return Row(
      children: [
        for (final color in colors)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PlayerSlot(
                controller: controller,
                color: color,
                top: top,
              ),
            ),
          ),
      ],
    );
  }
}

/// Carte joueur avec sa flèche orange. La flèche est posée hors de la rotation,
/// côté plateau, et pointe vers la carte active.
class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.controller,
    required this.color,
    required this.top,
  });

  final LudoController controller;
  final LudoColor color;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final active = controller.game.turn == color && !controller.roundOver;
    final card = _PlayerCard(
      controller: controller,
      color: color,
      active: active,
    );
    final arrow = Center(
      child: Opacity(
        opacity: active ? 1 : 0,
        child: Icon(
          top ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          size: 30,
          color: const Color(0xFFFF8A00),
        ),
      ),
    );
    // Cartes du haut : pas de rotation (#124), le texte reste lisible pour tous les joueurs.
    final turned = card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: top ? [turned, arrow] : [arrow, turned],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.controller,
    required this.color,
    required this.active,
  });

  final LudoController controller;
  final LudoColor color;
  final bool active;

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  String _placeText(int place) {
    if (place == 0) return 'au centre';
    return '${place == 1 ? '1er' : '${place}e'} ✓';
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final tone = _toneOf(color).fill;
    final rolledHere = game.diceOwner == color && game.dice != null;
    final clickable = active && controller.canRoll;
    final arrived = game.tokens
        .where((t) => t.color == color && t.progress == ludoFinish)
        .length;

    final die = KeyedSubtree(
      key: rolledHere
          ? ValueKey('roll-${game.rollId}')
          : ValueKey('idle-${color.name}'),
      child: LudoDie(
        value: rolledHere ? game.dice : null,
        tone: tone,
        size: _dieSize,
        animate: rolledHere,
      ),
    );
    final dieWidget = active
        ? _RollableDie(
            pulse: clickable,
            onTap: clickable ? controller.roll : null,
            child: die,
          )
        : ColorFiltered(
            colorFilter: _grayscale,
            child: Opacity(opacity: 0.5, child: die),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFFFFD653) : _brown,
          width: active ? 3 : 2,
        ),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x66FFD653), spreadRadius: 2)]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                        border: Border.all(color: _brown),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _colorName(color, controller.solo).toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$arrived/4',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _placeText(game.rankings.indexOf(color) + 1),
                  style: const TextStyle(
                    color: Color(0x99202848),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          dieWidget,
        ],
      ),
    );
  }
}
