// Rendu des dominos : demi-tuile avec ses points, tuile de la main, serpentin de la chaîne.
// Géométrie reprise de DominoGameScreen.tsx (DominoHalf, DominoFace, ChainTile, DominoChain).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../game/domino.dart';

const _pipColor = Color(0xFF17304B);
const _faceColor = Color(0xFFFFF9E9);
const _edgeColor = Color(0xFF24364B);
// Style cartoon : contour sombre épais et ombre dure.
const _outlineColor = Color(0xFF1B2A44);
const _shadowColor = Color(0xFF0B1A33);

/// Position des points par valeur (mêmes emplacements que pipPositions du source).
const _pipLayouts = <int, List<String>>{
  0: [],
  1: ['center'],
  2: ['top-left', 'bottom-right'],
  3: ['top-left', 'center', 'bottom-right'],
  4: ['top-left', 'top-right', 'bottom-left', 'bottom-right'],
  5: ['top-left', 'top-right', 'center', 'bottom-left', 'bottom-right'],
  6: ['top-left', 'top-right', 'middle-left', 'middle-right', 'bottom-left', 'bottom-right'],
};

/// Une moitié de domino : des points à 18 % du bord, comme le CSS source.
class _HalfPainter extends CustomPainter {
  const _HalfPainter(this.value, {this.rotated = false});

  final int value;
  // Pierre posée à plat : le motif de points tourne de 90°, comme sur une vraie pierre.
  final bool rotated;

  @override
  void paint(Canvas canvas, Size size) {
    if (!rotated) {
      _paintPips(canvas, size);
      return;
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 2);
    canvas.translate(-size.height / 2, -size.width / 2);
    _paintPips(canvas, Size(size.height, size.width));
    canvas.restore();
  }

  void _paintPips(Canvas canvas, Size size) {
    final paint = Paint()..color = _pipColor;
    // Points ronds (même diamètre en largeur et en hauteur), taille proportionnelle à la plus petite dimension.
    final pipD = math.min(size.width, size.height) * 0.24;
    final pipW = pipD;
    final pipH = pipD;
    const inset = 0.18;
    for (final position in _pipLayouts[value] ?? const <String>[]) {
      final double x;
      final double y;
      switch (position) {
        case 'top-left':
          x = size.width * inset;
          y = size.height * inset;
        case 'top-right':
          x = size.width - size.width * inset - pipW;
          y = size.height * inset;
        case 'middle-left':
          x = size.width * inset;
          y = (size.height - pipH) / 2;
        case 'middle-right':
          x = size.width - size.width * inset - pipW;
          y = (size.height - pipH) / 2;
        case 'center':
          x = (size.width - pipW) / 2;
          y = (size.height - pipH) / 2;
        case 'bottom-left':
          x = size.width * inset;
          y = size.height - size.height * inset - pipH;
        default: // bottom-right
          x = size.width - size.width * inset - pipW;
          y = size.height - size.height * inset - pipH;
      }
      canvas.drawOval(Rect.fromLTWH(x, y, pipW, pipH), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.rotated != rotated;
}

/// Tuile complète (fond crème, bordure foncée, ombre dure). `horizontal` la couche à plat.
class DominoFace extends StatelessWidget {
  const DominoFace({
    super.key,
    required this.first,
    required this.second,
    required this.width,
    required this.height,
    this.horizontal = false,
    this.highlight = false,
  });

  final int first;
  final int second;
  final double width;
  final double height;
  final bool horizontal;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final halves = [
      // SizedBox.expand : sans cela, CustomPaint garde une taille nulle dans l'axe libre et rien ne s'affiche.
      Expanded(child: SizedBox.expand(child: CustomPaint(painter: _HalfPainter(first, rotated: horizontal)))),
      horizontal
          ? Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: _edgeColor.withValues(alpha: 0.5))
          : Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 3), color: _edgeColor.withValues(alpha: 0.5)),
      Expanded(child: SizedBox.expand(child: CustomPaint(painter: _HalfPainter(second, rotated: horizontal)))),
    ];
    return Semantics(
      label: 'Domino $first et $second',
      child: Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _faceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _outlineColor, width: 3),
        boxShadow: [
          const BoxShadow(color: _shadowColor, offset: Offset(0, 4)),
          if (highlight) const BoxShadow(color: Color(0xFFFDE047), spreadRadius: 3),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            horizontal ? Row(children: halves) : Column(children: halves),
            // Reflet cartoon : bande claire en haut à gauche, sans bloquer le toucher.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment(0.3, 0.3),
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Tuile posée dans la chaîne. Horizontale dans une rangée, verticale au virage.
class ChainTile extends StatelessWidget {
  const ChainTile({
    super.key,
    required this.tile,
    required this.length,
    required this.turn,
    required this.reverse,
    this.highlight = false,
    this.onTap,
  });

  final PlacedTile tile;
  final double length;
  final bool turn;
  final bool reverse;
  final bool highlight;
  final void Function(TapUpDetails details)? onTap;

  @override
  Widget build(BuildContext context) {
    final first = (turn || !reverse) ? tile.left : tile.right;
    final second = (turn || !reverse) ? tile.right : tile.left;
    final width = turn ? length / 2 : length;
    final height = turn ? length : length / 2;
    final face = DominoFace(
      first: first,
      second: second,
      width: width,
      height: height,
      horizontal: !turn,
      highlight: highlight,
    );
    if (onTap == null) return face;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: onTap,
      child: face,
    );
  }
}

/// Chaîne en serpentin, mise à l'échelle pour rester entièrement visible.
///
/// Changements par rapport au source :
/// - une rangée avec virage ne réserve que 2 épaisseurs (au lieu de 3), donc moins de vide entre les lignes ;
/// - la dernière rangée ne réserve qu'une épaisseur, sans marge inférieure ;
/// - la chaîne entière est réduite uniformément (FittedBox) quand elle dépasse la zone,
///   au lieu d'être coupée ou de défiler.
class DominoChain extends StatelessWidget {
  const DominoChain({
    super.key,
    required this.chain,
    required this.leftOpen,
    required this.rightOpen,
    required this.onEndTap,
  });

  final List<PlacedTile> chain;
  final bool leftOpen;
  final bool rightOpen;
  final void Function(DominoSide side) onEndTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = math.max(3, (availableWidth / (availableWidth < 420 ? 56 : 68)).floor());
        final perRow = columns - 1;
        // Largeur utile = perRow tuiles horizontales + une épaisseur pour le domino vertical de fin de ligne.
        final length = math.min(72.0, ((availableWidth / (perRow + 0.5) / 2).floor() * 2).toDouble());
        final thickness = length / 2;
        final totalWidth = perRow * length + thickness;

        // Chaque rangée : perRow horizontales, puis un vertical en bout de rangée (sauf la dernière).
        final groups = <List<PlacedTile>>[];
        var start = 0;
        while (chain.length - start > perRow) {
          final end = math.min(chain.length, start + perRow + 1);
          groups.add(chain.sublist(start, end));
          start = end;
        }
        if (start < chain.length) groups.add(chain.sublist(start));
        final last = chain.length - 1;

        // Toutes les pierres sont dans une seule pile, positionnées en absolu et animées :
        // quand la chaîne change, chaque pierre glisse vers sa nouvelle place au lieu de sauter.
        final tiles = <Widget>[];
        var top = 0.0;
        for (var rowIndex = 0; rowIndex < groups.length; rowIndex++) {
          final group = groups[rowIndex];
          final reverse = rowIndex.isOdd;
          // Une rangée a un virage seulement si elle contient perRow + 1 tuiles.
          final hasTurn = group.length == perRow + 1;
          for (var index = 0; index < group.length; index++) {
            final globalIndex = rowIndex * (perRow + 1) + index;
            final isTurn = hasTurn && index == perRow;
            final sides = <DominoSide>[
              if (globalIndex == 0 && leftOpen) DominoSide.left,
              if (globalIndex == last && rightOpen) DominoSide.right,
            ];
            void Function(TapUpDetails)? onTap;
            if (sides.isNotEmpty) {
              onTap = (details) {
                if (sides.length == 1) {
                  onEndTap(sides.first);
                } else {
                  final tileWidth = isTurn ? length / 2 : length;
                  onEndTap(details.localPosition.dx < tileWidth / 2 ? DominoSide.left : DominoSide.right);
                }
              };
            }
            final tile = ChainTile(
              tile: group[index],
              length: length,
              turn: isTurn,
              reverse: reverse,
              highlight: onTap != null,
              onTap: onTap,
            );
            final double left;
            final double tileWidth;
            final double tileHeight;
            if (isTurn) {
              // Vertical en bout de rangée, collé au bord de la dernière tuile de la rangée.
              left = reverse ? 0.0 : perRow * length;
              tileWidth = thickness;
              tileHeight = length;
            } else {
              // Horizontal : sens inverse sur les rangées impaires, en partant du bord du vertical.
              left = reverse ? totalWidth - (index + 1) * length : index * length;
              tileWidth = length;
              tileHeight = thickness;
            }
            tiles.add(AnimatedPositioned(
              key: ValueKey(group[index].id),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              width: tileWidth,
              height: tileHeight,
              child: sides.isNotEmpty
                  ? Semantics(button: true, label: Strings.dominoPlaceHere, child: tile)
                  : tile,
            ));
          }
          // Pas entre rangées = longueur du vertical (le domino horizontal suivant se pose dessous).
          top += hasTurn ? length : thickness;
        }
        final naturalHeight = top;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: totalWidth,
              height: naturalHeight,
              child: Stack(clipBehavior: Clip.none, children: tiles),
            ),
          ),
        );
      },
    );
  }
}
