import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';
import 'halftone_overlay.dart';

/// Fond de page BD (issue #636) : papier avec une trame de points légère,
/// dessinée sous le contenu pour ne pas gêner la lecture.
class ComicBackdrop extends StatelessWidget {
  const ComicBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ComicPalette.paper,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: HalftonePainter(
                    color: ComicPalette.backdropDots,
                    spacing: 14,
                    radius: 1.2,
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
