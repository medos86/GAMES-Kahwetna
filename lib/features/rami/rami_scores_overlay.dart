import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';

import '../../core/strings.dart';

const _overlayFrame = ComicPalette.ink;
const _overlayCream = Color(0xFFFFF8E7);
const _overlayInk = Color(0xFF20284B);
const _overlayGold = Color(0xFFFFE16B);

/// Onglet collé au bord haut du tapis : ouvre le panneau des scores (#528).
/// Il n'affiche que le libellé « Score » (#667) ; le détail est dans le panneau.
class RamiScoresTab extends StatelessWidget {
  const RamiScoresTab({
    super.key,
    required this.open,
    required this.myTurn,
    required this.onTap,
  });

  final bool open;
  final bool myTurn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: Strings.showScores,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
          decoration: BoxDecoration(
            color: myTurn ? _overlayGold : _overlayCream,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            border: Border.all(color: _overlayFrame, width: 2),
          ),
          child: ExcludeSemantics(
            child: Text(
              Strings.showScores,
              style: const TextStyle(
                color: _overlayInk,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Voile sombre derrière le panneau des scores (#591) : il s'estompe en même
/// temps que le panneau. Ignoré par les gestes quand le panneau est fermé.
class RamiScoresScrim extends StatelessWidget {
  const RamiScoresScrim({super.key, required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: open ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: const ColoredBox(color: Colors.black26),
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
    this.feltColor,
    this.frameColor,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;

  /// Couleurs du tapis (#838) : le panneau prend le vert et le cadre du tapis, pour sembler sorti de lui.
  final Color? feltColor;
  final Color? frameColor;

  @override
  Widget build(BuildContext context) {
    final felt = feltColor;
    final integrated = felt != null;
    final ink = integrated ? _overlayCream : _overlayInk;
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
              color: felt ?? _overlayCream,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: Border.all(
                color: frameColor ?? _overlayFrame,
                width: integrated ? 6 : 3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                TextButton.icon(
                  onPressed: onClose,
                  icon: Icon(Icons.keyboard_arrow_up, color: ink),
                  label: Text(
                    Strings.hideScores,
                    style: TextStyle(
                      color: ink,
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
