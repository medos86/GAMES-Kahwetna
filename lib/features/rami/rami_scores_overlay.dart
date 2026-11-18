import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';

const _overlayFrame = Color(0xFF4A2A10);
const _overlayCream = Color(0xFFFFF8E7);
const _overlayInk = Color(0xFF20284B);
const _overlayGold = Color(0xFFFFE16B);

/// Onglet collé au bord haut du tapis : ouvre le panneau des scores (#528).
class RamiScoresTab extends StatelessWidget {
  const RamiScoresTab({
    super.key,
    required this.open,
    required this.myScore,
    required this.myTurn,
    required this.turnLabel,
    required this.onTap,
  });

  final bool open;
  final int myScore;
  final bool myTurn;
  final String turnLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: '$turnLabel · $myScore',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 2, 10, 4),
          decoration: BoxDecoration(
            color: myTurn ? _overlayGold : _overlayCream,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            border: Border.all(color: _overlayFrame, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$turnLabel · $myScore',
                style: const TextStyle(
                  color: _overlayInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(
                open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: _overlayInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panneau des scores : glisse depuis le haut, avec un bouton pour le refermer (#528).
class RamiScoresPanel extends StatelessWidget {
  const RamiScoresPanel({
    super.key,
    required this.open,
    required this.onClose,
    required this.child,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedSlide(
        offset: open ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: open ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              color: _overlayCream,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: Border.all(color: _overlayFrame, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_up, color: _overlayInk),
                  label: Text(
                    Strings.hideScores,
                    style: const TextStyle(
                      color: _overlayInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
