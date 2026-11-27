part of '../chkobba_screen.dart';

/// Cartes restantes à distribuer (#983) : simple pastille, sans dos de cartes empilés.
class ChkobbaDeckCounter extends StatelessWidget {
  const ChkobbaDeckCounter({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        '$count à distribuer',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: ScobaPalette.ink,
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
      // Éventail : chaque carte recouvre la précédente d'environ 45 %.
      final step = widget.width * 0.55;
      return SizedBox(
        width: widget.width + 2 * step,
        height: widget.height + 14,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < layout.length; i++)
              if (layout[i] != null)
                Positioned(
                  left: step * i,
                  top: 0,
                  width: widget.width,
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
