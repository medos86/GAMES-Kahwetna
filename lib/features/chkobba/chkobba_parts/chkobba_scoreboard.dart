part of '../chkobba_screen.dart';

/// Taille de l'avatar inactif et de l'avatar du joueur dont c'est le tour, en dp.
/// Mêmes tailles que les médaillons de la Belote (`_SeatInfo`).
const double _sideAvatarSize = 34;
const double _sideAvatarActiveSize = 48;

/// Coin d'un joueur, mis en page comme à la Belote (`_SeatInfo`) : avatar, pastille du pseudo,
/// puis pastille du score (même style que le score de la Belote). La pile gagnée et la pioche
/// sont dans l'autre coin de la même rangée (voir `_SeatRow`).
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    super.key,
    required this.game,
    required this.player,
    required this.name,
    required this.color,
    required this.avatarId,
    this.spinTick = 0,
    required this.avatarKey,
  });

  final ChkobbaState game;
  final Player player;
  final String name;
  final Color color;
  final String avatarId;

  /// Compteur de prises : chaque hausse fait tourner l'avatar une fois (#988).
  final int spinTick;

  /// Repère des cartes gagnées : elles volent vers l'avatar et s'y cachent (#1018).
  final GlobalKey avatarKey;

  @override
  Widget build(BuildContext context) {
    final finished = game.winner != null;
    final winners = game.winner == null ? <int>[] : [game.winner!.index];
    final score = game.scores[player]!;
    final active = game.winner == null && game.turn == player;
    final avatarState = gameAvatarState(
      seat: player.index,
      finished: finished,
      winners: winners,
    );
    final avatar = TurnAvatar(
      tone: color,
      active: active,
      avatarId: avatarId,
      state: avatarState,
      semanticLabel: name,
      baseSize: _sideAvatarSize,
      activeSize: _sideAvatarActiveSize,
    );
    // Anneau 3D couleur du joueur (bleu, rouge pour l'adversaire).
    final ring = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 3),
            blurRadius: 2,
          ),
        ],
      ),
      child: avatar,
    );
    // Avatar et gains tournent ensemble (#988). Emplacement de taille fixe (#954).
    // Appui sur l'avatar : popup avec les cartes gagnées et les Chkobbas (#984).
    final avatarSlot = GestureDetector(
      key: ValueKey('seat-avatar:${player.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => ChkobbaSeatInfo.show(
        context,
        name: name,
        wonCards: game.won[player]?.length ?? 0,
        chkobbas: game.chkobbas[player] ?? 0,
        avatarId: avatarId,
        avatarState: avatarState,
      ),
      child: ChkobbaAvatarFlip(
        trigger: spinTick,
        child: SizedBox(
          key: avatarKey,
          width: _sideAvatarActiveSize + 8,
          height: _sideAvatarActiveSize + 8,
          child: Center(child: ring),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: '$name $score',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatarSlot,
          const SizedBox(height: 2),
          _NamePill(name: name, active: active),
          const SizedBox(height: 4),
          _ScorePill(score: score, color: color),
        ],
      ),
    );
  }
}

/// Pastille du pseudo, comme la Belote : dorée quand c'est son tour, sombre sinon.
class _NamePill extends StatelessWidget {
  const _NamePill({required this.name, required this.active});

  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            active ? ComicPalette.gold : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? ComicPalette.ink : Colors.black26,
          width: 2,
        ),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: active ? const Color(0xFF513B00) : ComicPalette.white,
        ),
      ),
    );
  }
}

/// Pastille du score, comme le score d'équipe de la Belote : fond blanc, chiffre à la couleur du joueur.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ComicPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '$score',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

/// Avatar qui fait un tour complet sur lui-même (rotation 3D) à chaque hausse de [trigger] (#988).
/// Revient à l'état initial à la fin : plus de transformation, donc pas de saut visuel.
class ChkobbaAvatarFlip extends StatefulWidget {
  const ChkobbaAvatarFlip({
    super.key,
    required this.trigger,
    required this.child,
  });

  final int trigger;
  final Widget child;

  static const Duration duration = Duration(milliseconds: 600);

  @override
  State<ChkobbaAvatarFlip> createState() => _ChkobbaAvatarFlipState();
}

class _ChkobbaAvatarFlipState extends State<ChkobbaAvatarFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ChkobbaAvatarFlip.duration,
    )..addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    // Tour terminé : l'angle revient à zéro, la transformation disparaît.
    if (status == AnimationStatus.completed) _controller.reset();
  }

  @override
  void didUpdateWidget(ChkobbaAvatarFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == oldWidget.trigger) return;
    if (!cardAnimations.value || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.value == 0) return child!;
        final angle = _controller.value * 2 * math.pi;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          key: const ValueKey('chkobba-avatar-flip'),
          alignment: Alignment.center,
          transform: transform,
          child: child,
        );
      },
    );
  }
}
