part of '../chkobba_screen.dart';

/// Rangée d'un joueur (#800) : un coin à gauche, la main au centre, un coin à droite.
/// Les coins restent sur la rangée : le tapis garde toute la hauteur libre entre elles.
class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.corner,
    required this.left,
    required this.hand,
    required this.right,
    required this.height,
  });

  /// Largeur de chaque coin latéral.
  final double corner;
  final Widget left;
  final Widget hand;
  final Widget right;

  /// Hauteur fixe de la rangée (#909) : le tapis garde sa place quand le contenu change.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(width: corner, child: left),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: hand),
            ),
          ),
          SizedBox(width: corner, child: right),
        ],
      ),
    );
  }
}
