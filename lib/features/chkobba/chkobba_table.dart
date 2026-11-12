import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';
import '../../widgets/comic/action_burst.dart';

const double _zelligeBand = 6;

/// Tapis de Chkobba : cadre, feutre, coins noirs, bordure zellige (si activée), cartes en grille.
/// `cards` contient un élément par emplacement ; null = emplacement vide.
class ChkobbaTable extends StatelessWidget {
  const ChkobbaTable({super.key, required this.cards, required this.columns, this.emptyLabel});

  final List<Widget?> cards;
  final int columns;

  /// Texte affiché au centre quand la table est vide (« Chkobba ! »).
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.current;
    final rows = math.max(1, (cards.length / columns).ceil());
    // Ratio du tapis : colonnes × 5 / lignes × 7, comme le source React.
    final ratio = (columns * 5) / (rows * 7);
    final tableEmpty = cards.whereType<Widget>().isEmpty;
    final inset = style.showZellige ? _zelligeBand + 8 : 10.0;

    return AspectRatio(
      aspectRatio: ratio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.frame,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: style.outline, width: 3),
          boxShadow: [BoxShadow(color: style.outline, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: BoxDecoration(color: style.felt)),
                CustomPaint(painter: _DotsPainter()),
                if (style.showZellige) CustomPaint(painter: _ComicBorderPainter(style)),
                // Coins noirs épais, comme les décorations du source React.
                const Positioned(left: 8, top: 8, child: _Corner(top: true, left: true)),
                const Positioned(right: 8, top: 8, child: _Corner(top: true, left: false)),
                const Positioned(left: 8, bottom: 8, child: _Corner(top: false, left: true)),
                const Positioned(right: 8, bottom: 8, child: _Corner(top: false, left: false)),
                Padding(
                  padding: EdgeInsets.all(inset),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cellW = c.maxWidth / columns;
                      final cellH = c.maxHeight / rows;
                      return Stack(
                        children: [
                          for (var i = 0; i < cards.length; i++)
                            if (cards[i] != null)
                              Positioned(
                                left: (i % columns) * cellW + 3,
                                top: (i ~/ columns) * cellH + 3,
                                width: cellW - 6,
                                height: cellH - 6,
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
                      colors: style.chkobbaGradient,
                      angle: -0.1,
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

/// Bannière comic (texte contouré, dégradé, légèrement penchée) : « Chkobba ! », « 7AYA ! ».
class ChkobbaBanner extends StatelessWidget {
  const ChkobbaBanner({super.key, required this.text, required this.colors, this.angle = -0.1});

  final String text;
  final List<Color> colors;
  final double angle;

  @override
  Widget build(BuildContext context) {
    // Style BD (issue #97) : éclat d'impact au lieu de la bannière dégradée.
    if (kComicChkobba) return ActionBurst(text: text, size: 150);
    final style = GameStyle.current;
    const base = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1);
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
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(0, 6))],
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

/// Coin décoratif : deux bords noirs épais formant un angle.
class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.black, width: 4);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
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

/// Bordure fine du tapis : bande étroite avec une trame de points très légère.
class _ComicBorderPainter extends CustomPainter {
  const _ComicBorderPainter(this.style);

  final GameStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    const b = _zelligeBand;
    final band = Paint()..color = style.zellige;
    final dot = Paint()..color = style.outline.withValues(alpha: 0.33);
    final outline = Paint()
      ..color = style.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rects = [
      Rect.fromLTWH(0, 0, size.width, b),
      Rect.fromLTWH(0, size.height - b, size.width, b),
      Rect.fromLTWH(0, 0, b, size.height),
      Rect.fromLTWH(size.width - b, 0, b, size.height),
    ];
    for (final r in rects) {
      canvas.drawRect(r, band);
      // Trame de points (halftone BD).
      for (double y = r.top + 1.5; y < r.bottom; y += 3) {
        for (double x = r.left + 1.5; x < r.right; x += 3) {
          canvas.drawCircle(Offset(x, y), 0.5, dot);
        }
      }
      canvas.drawRect(r, outline..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _ComicBorderPainter oldDelegate) => oldDelegate.style != style;
}
