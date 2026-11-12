import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';

/// Contour d'encre épais autour de [child] (issue #94).
class InkOutline extends StatelessWidget {
  const InkOutline({
    super.key,
    required this.child,
    this.width = 3,
    this.radius = 12,
    this.color = ComicPalette.ink,
  });

  final Widget child;
  final double width;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: width),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
