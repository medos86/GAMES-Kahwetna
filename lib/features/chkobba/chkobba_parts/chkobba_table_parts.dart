part of '../chkobba_screen.dart';

/// Pioche : cartes empilées posées directement sur le tapis (sans cadre carré),
/// avec le nombre de cartes restantes. Issue #685 : intégrée au tapis.
class ChkobbaDeckPile extends StatelessWidget {
  const ChkobbaDeckPile({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    // Cartes aux coins arrondis et ombre douce, sans bordure carrée épaisse.
    Widget pile(Color color) => Container(
          width: 18,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ScobaPalette.ink, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(-4, 0),
                child: Transform.rotate(
                  angle: -0.2,
                  child: pile(ScobaPalette.blue),
                ),
              ),
              Transform.translate(
                offset: const Offset(4, 0),
                child: Transform.rotate(
                  angle: 0.2,
                  child: pile(ScobaPalette.red),
                ),
              ),
              pile(ScobaPalette.red),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: ScobaPalette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          t('draw'),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: ScobaPalette.ink,
          ),
        ),
      ],
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

/// « Tour de l'adversaire... », affiché pendant que l'IA réfléchit.
class _ThinkingBadge extends StatelessWidget {
  const _ThinkingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 5))],
      ),
      child: Semantics(
        liveRegion: true,
        child: const Text(
          "⏳ Tour de l'adversaire...",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
