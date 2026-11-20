import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Tapis vert BD à contour encre (guide §8 : FeltPanel ; palette de #634).
class FeltPanel extends StatelessWidget {
  const FeltPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static const Color _felt = ComicPalette.felt;
  static const Color _frame = ComicPalette.ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _felt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _frame, width: 6),
        // comicShadow(ring: 3, drop: 8, blur: 20)
        boxShadow: const [
          BoxShadow(color: _frame, spreadRadius: 3),
          BoxShadow(color: _frame, spreadRadius: 3, offset: Offset(0, 8)),
          BoxShadow(
            color: Color(0x4D281405),
            spreadRadius: 3,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
