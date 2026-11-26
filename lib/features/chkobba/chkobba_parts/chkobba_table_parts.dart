part of '../chkobba_screen.dart';

/// Compteur des cartes à distribuer (#983) : remplace la pioche. Une barre se vide
/// au fil des distributions, le nombre indique ce qu'il reste à donner.
class ChkobbaDeckCounter extends StatelessWidget {
  const ChkobbaDeckCounter({super.key, required this.count, this.total = 40});

  /// Cartes encore non distribuées.
  final int count;

  /// Nombre de cartes du jeu complet, pour la proportion de la barre.
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: ScobaPalette.ink,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            height: 6,
            child: Stack(
              children: [
                const ColoredBox(
                  color: Color(0x33000000),
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  alignment: Alignment.centerLeft,
                  child: const ColoredBox(
                    color: Color(0xFF2E7D32),
                    child: SizedBox.expand(),
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
  });

  final List<ChkobbaCard> cards;
  final double width;
  final double height;
  final Widget Function(ChkobbaCard card) builder;

  @override
  State<_Hand> createState() => _HandState();
}

class _HandState extends State<_Hand> {
  Map<String, int> _slots = {};

  @override
  Widget build(BuildContext context) {
    _slots = assignTableSlots(_slots, [for (final c in widget.cards) c.id]);
    final layout = handLayout(_slots, widget.cards);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < layout.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: layout[i] != null
                ? widget.builder(layout[i]!)
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
