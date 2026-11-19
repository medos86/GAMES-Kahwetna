part of '../ludo_screen.dart';

class _Board extends StatelessWidget {
  const _Board({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final u = side / ludoBoardUnits;
        final legal = controller.legalIds;
        return Semantics(
          label: t('ludoBoard'),
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _brown, width: 6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final color in LudoColor.values)
                      _cornerHouse(color, u),
                    for (final color in LudoColor.values)
                      for (var slot = 0; slot < ludoBaseSlots.length; slot++)
                        _at(
                          left: (ludoCorner(color).col +
                                  ludoBaseSlots[slot][1] -
                                  0.4) *
                              u,
                          top: (ludoCorner(color).row +
                                  ludoBaseSlots[slot][0] -
                                  0.4) *
                              u,
                          size: 0.8 * u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _brown.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    for (var index = 0; index < ludoTrack.length; index++)
                      _trackCell(index, ludoTrack[index], u),
                    for (final color in LudoColor.values)
                      for (var step = 0;
                          step < ludoHomeColumn(color).length;
                          step++)
                        _at(
                          left: ludoHomeColumn(color)[step].col * u,
                          top: ludoHomeColumn(color)[step].row * u,
                          size: u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _toneOf(color).fill,
                              border: Border.all(
                                color: _brown.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                    _at(
                      left: 6 * u,
                      top: 6 * u,
                      size: 3 * u,
                      child: const _CenterPiece(),
                    ),
                    for (final placed in layoutTokens(controller.game.tokens))
                      Positioned(
                        key: ValueKey(
                          '${placed.token.id}-${controller.jumpRevision}',
                        ),
                        left: placed.x * u - _tokenHitSize(placed.size * u) / 2,
                        top: placed.y * u - _tokenHitSize(placed.size * u) / 2,
                        width: _tokenHitSize(placed.size * u),
                        height: _tokenHitSize(placed.size * u),
                        child: _HopToken(
                          placed: placed,
                          u: u,
                          clickable: legal.contains(placed.token.id),
                          onTap: () => controller.tapToken(placed.token.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Carré positionné dans le Stack du plateau (coordonnées en pixels). Doit rester un `Positioned`
/// direct : un Stack ne accepte pas un widget qui en enveloppe un autre.
Positioned _at({
  required double left,
  required double top,
  required double size,
  required Widget child,
}) =>
    Positioned(left: left, top: top, width: size, height: size, child: child);

Positioned _cornerHouse(LudoColor color, double u) {
  final corner = ludoCorner(color);
  final tone = _toneOf(color);
  return _at(
    left: corner.col * u,
    top: corner.row * u,
    size: 6 * u,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brown, width: 3),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.84,
          heightFactor: 0.84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tone.fill.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    ),
  );
}

Positioned _trackCell(int index, Cell cell, double u) {
  LudoColor? starter;
  for (final color in LudoColor.values) {
    if (ludoStartIndex(color) == index) starter = color;
  }
  final isSafe = ludoSafeIndexes.contains(index);
  return _at(
    left: cell.col * u,
    top: cell.row * u,
    size: u,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: starter != null ? _toneOf(starter).fill : _cream,
        border: Border.all(color: _brown.withValues(alpha: 0.3)),
      ),
      child: isSafe && starter == null
          ? Center(
              child: Icon(
                Icons.star,
                size: u * 0.75,
                color: kLudoSafeStarColor,
              ),
            )
          : null,
    ),
  );
}

/// Centre du plateau : quatre triangles, un par couleur (arrivée propre à chaque joueur, #378).
class _CenterPiece extends StatelessWidget {
  const _CenterPiece();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GoalPainter());
  }
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w / 2, h / 2);
    // Chaque couleur occupe le côté du centre où se trouve sa maison.
    final sides = <LudoColor, List<Offset>>{
      LudoColor.red: [Offset(0, 0), Offset(0, h)],
      LudoColor.green: [Offset(0, 0), Offset(w, 0)],
      LudoColor.yellow: [Offset(w, 0), Offset(w, h)],
      LudoColor.blue: [Offset(0, h), Offset(w, h)],
    };
    final edge = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final entry in sides.entries) {
      final points = entry.value;
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(centre.dx, centre.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _toneOf(entry.key).fill);
      canvas.drawPath(path, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) => false;
}

/// Pion qui saute case par case jusqu'à sa nouvelle position (#378).
/// Le Positioned du plateau reste à l'arrivée ; seul le décalage visuel anime le trajet.
class _HopToken extends StatefulWidget {
  const _HopToken({
    required this.placed,
    required this.u,
    required this.clickable,
    required this.onTap,
  });

  final PlacedToken placed;
  final double u;
  final bool clickable;
  final VoidCallback onTap;

  @override
  State<_HopToken> createState() => _HopTokenState();
}

class _HopTokenState extends State<_HopToken>
    with SingleTickerProviderStateMixin {
  static const _msPerCell = 150;
  static const _jumpHeight = 0.45; // hauteur du saut, en unités de case

  late final AnimationController _hop =
      AnimationController(vsync: this, duration: Duration.zero);

  // Points du trajet (unités de case), le dernier est la position finale.
  List<({double x, double y})> _path = const [];

  // Longueur cumulée du trajet à chaque point : la vitesse reste constante (#386).
  List<double> _lengths = const [0];

  void _setPath(List<({double x, double y})> points) {
    _path = points;
    _lengths = [0];
    for (var i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      _lengths.add(_lengths.last + math.sqrt(dx * dx + dy * dy));
    }
  }

  @override
  void didUpdateWidget(covariant _HopToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.placed;
    final after = widget.placed;
    final from = before.token.progress;
    final to = after.token.progress;
    if (from == to || to == 0 || MediaQuery.disableAnimationsOf(context)) {
      _hop.stop();
      _path = const [];
      return;
    }
    _setPath([
      (x: before.x, y: before.y),
      ...ludoHopWaypoints(after.token.color, from, to),
      (x: after.x, y: after.y),
    ]);
    _hop
      ..duration = Duration(milliseconds: (_msPerCell * _lengths.last).round())
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  /// Décalage visuel par rapport à la position finale, saut compris.
  Offset _offset() {
    if (_path.length < 2 || _lengths.last == 0) return Offset.zero;
    // Position le long du trajet, à vitesse constante (distance réelle, pas nombre de cases).
    final s = _hop.value * _lengths.last;
    var i = 0;
    while (i < _path.length - 2 && _lengths[i + 1] < s) {
      i++;
    }
    final segment = _lengths[i + 1] - _lengths[i];
    final local = segment == 0 ? 0.0 : (s - _lengths[i]) / segment;
    final a = _path[i];
    final b = _path[i + 1];
    final x = a.x + (b.x - a.x) * local;
    final y = a.y + (b.y - a.y) * local;
    final lift = math.sin(math.pi * local) * _jumpHeight;
    final end = _path.last;
    return Offset((x - end.x) * widget.u, (y - lift - end.y) * widget.u);
  }

  @override
  Widget build(BuildContext context) {
    final placed = widget.placed;
    // Pion jouable : un peu plus grand, avec halo pulsé.
    final visual = placed.size * widget.u * (widget.clickable ? 1.12 : 1);
    return AnimatedBuilder(
      animation: _hop,
      builder: (context, child) =>
          Transform.translate(offset: _offset(), child: child),
      child: PulseGlow(
        active: widget.clickable,
        radius: visual / 2,
        child: _TokenButton(
          token: placed.token,
          clickable: widget.clickable,
          onTap: widget.onTap,
          visualSize: visual,
        ),
      ),
    );
  }
}

/// Zone tactile d'un pion : au moins 44 px (issue #23), même si le pion dessiné est plus petit.
double _tokenHitSize(double visual) => math.max(visual, 44);

class _TokenButton extends StatelessWidget {
  const _TokenButton({
    required this.token,
    required this.clickable,
    required this.onTap,
    required this.visualSize,
  });

  final Token token;
  final bool clickable;
  final VoidCallback onTap;

  /// Taille du pion dessiné, centré dans la zone tactile.
  final double visualSize;

  @override
  Widget build(BuildContext context) {
    final tone = _toneOf(token.color);
    return Semantics(
      button: clickable,
      label: tf('sPawn', {'c': tone.name}) + (clickable ? t('sToMove') : ''),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: clickable ? onTap : null,
        child: Center(
          child: SizedBox(
            width: visualSize,
            height: visualSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [Colors.white, tone.fill, tone.dark],
                  stops: const [0.1, 0.38, 1],
                ),
                border: Border.all(
                  color: clickable ? Colors.white : _brown,
                  width: clickable ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(color: _brown, offset: Offset(0, 3)),
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
