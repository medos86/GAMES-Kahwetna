import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/game_style.dart';
import '../../core/theme/scoba_palette.dart';
import '../../widgets/comic/action_burst.dart';

/// Tapis de Chkobba (#745) : feutre vert sans cadre intérieur (#766 retiré), cartes en grille.
/// `cards` contient un élément par emplacement ; null = emplacement vide.
class ChkobbaTable extends StatelessWidget {
  const ChkobbaTable({
    super.key,
    required this.cards,
    required this.columns,
    this.emptyLabel,
  });

  final List<Widget?> cards;
  final int columns;

  /// Texte affiché au centre quand la table est vide (« Chkobba ! »).
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final rows = math.max(1, (cards.length / columns).ceil());
    // Ratio du tapis : colonnes × 5 / lignes × 7, comme le source React.
    final ratio = (columns * 5) / (rows * 7);
    final tableEmpty = cards.whereType<Widget>().isEmpty;

    // Pas de cadre intérieur : seul le feutre vert reste, les cartes occupent presque toute la place.
    return AspectRatio(
      aspectRatio: ratio,
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: ScobaPalette.tapisVert),
            ),
            CustomPaint(painter: _DotsPainter()),
            Padding(
              padding: const EdgeInsets.all(2),
              child: LayoutBuilder(
                builder: (context, c) {
                  final cellW = c.maxWidth / columns;
                  final cellH = c.maxHeight / rows;
                  return Stack(
                    children: [
                      for (var i = 0; i < cards.length; i++)
                        if (cards[i] != null)
                          Positioned(
                            left: (i % columns) * cellW + 1,
                            top: (i ~/ columns) * cellH + 1,
                            width: cellW - 2,
                            height: cellH - 2,
                            child: cards[i]!,
                          ),
                    ],
                  );
                },
              ),
            ),
            if (tableEmpty && emptyLabel != null)
              Center(
                child: ChkobbaBanner(
                  text: emptyLabel!,
                  colors: GameStyle.current.chkobbaGradient,
                  angle: -0.1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bannière comic (texte contouré, dégradé, légèrement penchée) : « Chkobba ! », « 7AYA ! ».
class ChkobbaBanner extends StatelessWidget {
  const ChkobbaBanner({
    super.key,
    required this.text,
    required this.colors,
    this.angle = -0.1,
    this.burstSize = 150,
  });

  final String text;
  final List<Color> colors;
  final double angle;

  /// Taille de l'éclat BD (style comic) : plus petite pour « 7AYA ! » (#364).
  final double burstSize;

  @override
  Widget build(BuildContext context) {
    // Style BD (issue #97) : éclat d'impact au lieu de la bannière dégradée.
    if (kComicChkobba) return ActionBurst(text: text, size: burstSize);
    final style = GameStyle.current;
    const base = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      height: 1.1,
    );
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: style.outline, width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = style.outline,
              ),
            ),
            Text(text, style: base.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Trame de points très légère sur le feutre (halftone du source React).
class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1A000000);
    for (double y = 4; y < size.height; y += 8) {
      for (double x = 4; x < size.width; x += 8) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
