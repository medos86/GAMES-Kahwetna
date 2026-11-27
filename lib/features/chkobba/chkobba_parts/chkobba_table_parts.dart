part of '../chkobba_screen.dart';

/// Alerte « dernier tour » (pioche vide) : bulle BD avec clochette qui oscille et son unique.
class ChkobbaLastTurnAlert extends StatefulWidget {
  const ChkobbaLastTurnAlert({super.key});

  @override
  State<ChkobbaLastTurnAlert> createState() => _ChkobbaLastTurnAlertState();
}

class _ChkobbaLastTurnAlertState extends State<ChkobbaLastTurnAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Sounds.play(Sfx.bell);
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: t('sLastTurn'),
      child: ExcludeSemantics(
        child: ComicPanel(
          color: ComicPalette.yellow,
          outlineColor: ComicPalette.ink,
          radius: 10,
          shadowOffset: const Offset(4, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _swing,
                builder: (context, child) => Transform.rotate(
                  angle: (_swing.value - 0.5) * 0.7,
                  child: child,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  size: 26,
                  color: ComicPalette.ink,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    t('sLastTurn'),
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: ComicPalette.ink,
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

/// Place chaque carte dans son emplacement (0 à 2) ; `null` = emplacement vide.
List<ChkobbaCard?> handLayout(Map<String, int> slots, List<ChkobbaCard> cards) {
  final layout = List<ChkobbaCard?>.filled(3, null);
  for (final card in cards) {
    final slot = slots[card.id];
    if (slot != null && slot < layout.length) layout[slot] = card;
  }
  return layout;
}

/// Trois emplacements fixes : une carte garde sa place quand une autre part (#494).
class _Hand extends StatefulWidget {
  const _Hand({
    required this.cards,
    required this.width,
    required this.height,
    required this.builder,
    this.arc = false,
    this.mirror = false,
  });

  final List<ChkobbaCard> cards;

  /// Cartes en éventail (arc), comme en main.
  final bool arc;

  /// Éventail retourné (adversaire, en haut de l'écran).
  final bool mirror;
  final double width;
  final double height;
  final Widget Function(ChkobbaCard card) builder;

  @override
  State<_Hand> createState() => _HandState();
}

class _HandState extends State<_Hand> {
  Map<String, int> _slots = {};

  /// Éventail : cartes qui se chevauchent, le milieu reste droit, les bords
  /// penchent vers l'extérieur et descendent (arc en arc-en-ciel), ou montent
  /// pour l'adversaire.
  Widget _fan(int slot, Widget child) {
    if (!widget.arc) return child;
    final t = slot - 1; // -1, 0, 1
    final dir = widget.mirror ? -1.0 : 1.0;
    return Transform.translate(
      offset: Offset(0, dir * t.abs() * 10),
      child: Transform.rotate(
        angle: t * 0.22 * dir,
        alignment: widget.mirror ? Alignment.topCenter : Alignment.bottomCenter,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _slots = assignTableSlots(_slots, [for (final c in widget.cards) c.id]);
    final layout = handLayout(_slots, widget.cards);
    if (widget.arc) {
      // Éventail : la carte garde son format (480 x 707) ; chaque carte
      // recouvre la précédente d'environ 45 %.
      final byHeight = widget.height * 480 / 707;
      final faceW = widget.width < byHeight ? widget.width : byHeight;
      final step = faceW * 0.55;
      return SizedBox(
        width: faceW + 2 * step,
        height: widget.height + 14,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < layout.length; i++)
              if (layout[i] != null)
                Positioned(
                  left: step * i,
                  top: 0,
                  width: faceW,
                  height: widget.height,
                  child: _fan(i, widget.builder(layout[i]!)),
                ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < layout.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: layout[i] != null
                ? _fan(i, widget.builder(layout[i]!))
                : const _EmptySlot(),
          ),
        ],
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x26FFFFFF), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
