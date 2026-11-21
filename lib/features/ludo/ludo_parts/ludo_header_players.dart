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

/// Vainqueur de la partie : premier du classement, seulement une fois finie.
List<int> _ludoWinners(LudoController controller) {
  final rankings = controller.game.rankings;
  if (rankings.isEmpty) return const [];
  return [rankings.first.index];
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.difficulty,
  });

  final LudoController controller;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final count = controller.playerCount;
    // Avatars (#621) : désormais sur chaque carte joueur, plus en haut de l'écran.
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

/// Taille du dé affiché sur la carte d'un joueur (#621 : agrandi).
const _dieSize = 52.0;

/// Une rangée de deux cartes joueurs. La rangée du haut (rouge, vert) est retournée à 180°.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.controller,
    required this.top,
    required this.avatarIds,
  });

  final LudoController controller;
  final bool top;

  /// Avatar par couleur (issue #553).
  final Map<LudoColor, String> avatarIds;

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
                avatarId: avatarIds[color] ?? defaultAvatar.id,
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
    required this.avatarId,
  });

  final LudoController controller;
  final LudoColor color;
  final bool top;
  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final active = controller.game.turn == color && !controller.roundOver;
    final card = _PlayerCard(
      controller: controller,
      color: color,
      active: active,
      avatarId: avatarId,
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
    required this.avatarId,
  });

  final LudoController controller;
  final LudoColor color;
  final bool active;

  /// Avatar propre à ce joueur (#621) : un seul, entouré de sa couleur.
  final String avatarId;

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

  /// Rang affiché sous l'avatar (#621 : le mot « au centre » n'est plus affiché).
  String _placeText(int place) {
    if (place == 0) return '';
    return '${place == 1 ? '1er' : '${place}e'} ✓';
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final tone = _toneOf(color).fill;
    final rolledHere = game.diceOwner == color && game.dice != null;
    final clickable = active && controller.canRoll;
    final finished = controller.roundOver;
    final winners = _ludoWinners(controller);
    final place = _placeText(game.rankings.indexOf(color) + 1);

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
          // Un seul avatar, entouré de la couleur du joueur (#621).
          // Le nom reste accessible (lecteur d'écran) mais n'est plus affiché.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tone, width: 3),
            ),
            child: ClipOval(
              child: AvatarView(
                avatarId: avatarId,
                state: gameAvatarState(
                  seat: color.index,
                  finished: finished,
                  winners: winners,
                ),
                size: 34,
                // Joueur dont c'est le tour : pleine opacité, sans grisé (#663).
                // Les autres restent atténués. Le cercle de la couleur fait office d'anneau.
                isActive: active,
                semanticLabel: _colorName(color, controller.solo),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (place.isNotEmpty)
                  Text(
                    place,
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
