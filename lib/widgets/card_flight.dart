import 'dart:async';

import 'package:flutter/scheduler.dart' show Ticker;
import 'package:material_ui/material_ui.dart';

import '../core/services/card_animations.dart';

/// Position écran d'un widget identifié par [key], ou null s'il n'est pas affiché (#238).
Rect? rectOfKey(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Fait voler [child] de [from] vers la position courante de [to] (#224).
/// [to] est relue à chaque image : si la mise en page bouge pendant le vol
/// (main qui se recentre, pile qui change), la carte suit sa vraie place.
/// [delay] retarde le départ (distributions échelonnées), sans second minuteur.
/// [hold] garde la carte visible à [from] pendant le délai, au lieu de la cacher.
/// [occluder] : zone (ex. tableau de score) que la carte traverse sans la
/// recouvrir ; sa partie au-dessus du bord bas de la zone est masquée (#357).
/// Sans effet si le réglage est coupé, si le système réduit les animations,
/// ou si [from] / la cible initiale est absente.
///
/// Tous les vols d'un même overlay partagent une seule couche et un seul
/// minuteur (#1058) : pas de [OverlayEntry] ni d'animation par carte.
Future<void> flyCard({
  required BuildContext context,
  required Rect? from,
  required Rect? Function() to,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Duration delay = Duration.zero,
  bool hold = false,
  Rect? Function()? occluder,
  Curve curve = Curves.easeInOutCubic,
}) {
  final start = to();
  if (from == null || start == null) return Future<void>.value();
  if (!cardAnimations.value || MediaQuery.disableAnimationsOf(context)) {
    return Future<void>.value();
  }
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return Future<void>.value();

  var layer = _layers[overlay];
  if (layer == null) {
    layer = _FlightLayer(overlay);
    _layers[overlay] = layer;
  }
  final flight = _Flight(
    from: from,
    to: to,
    lastTo: start,
    child: child,
    duration: duration,
    delay: delay,
    hold: hold,
    occluder: occluder,
    curve: curve,
  );
  layer.add(flight);
  return flight.done.future;
}

/// Une couche de vols par overlay (#1058).
final Expando<_FlightLayer> _layers = Expando<_FlightLayer>('flightLayer');

class _Flight {
  _Flight({
    required this.from,
    required this.to,
    required this.lastTo,
    required this.child,
    required this.duration,
    required this.delay,
    required this.hold,
    required this.occluder,
    required this.curve,
  });

  final Rect from;
  final Rect? Function() to;
  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool hold;
  final Rect? Function()? occluder;
  final Curve curve;
  final done = Completer<void>();

  /// Dernière cible connue : gardée si la cible disparaît en cours de vol.
  Rect lastTo;

  /// Instant du premier passage du minuteur : le vol démarre là.
  Duration? startedAt;
}

/// Couche unique d'un overlay : une [OverlayEntry] et un vue qui porte le minuteur (#1058).
class _FlightLayer {
  _FlightLayer(this.overlay) {
    _entry = OverlayEntry(builder: (_) => _FlightLayerView(layer: this));
    overlay.insert(_entry);
  }

  final OverlayState overlay;
  final List<_Flight> flights = [];
  late final OverlayEntry _entry;

  /// Vue montée, qui porte le minuteur ; null avant son montage ou après sa fin.
  _FlightLayerViewState? view;

  void add(_Flight flight) {
    flights.add(flight);
    view?.wake();
  }

}

/// Vue de la couche : son état possède le seul minuteur des vols.
/// Libéré avec l'overlay : pas de minuteur orphelin à la fermeture d'un écran (#1058).
class _FlightLayerView extends StatefulWidget {
  const _FlightLayerView({required this.layer});

  final _FlightLayer layer;

  @override
  State<_FlightLayerView> createState() => _FlightLayerViewState();
}

class _FlightLayerViewState extends State<_FlightLayerView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _now = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.layer.view = this;
    wake();
  }

  void wake() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    final layer = widget.layer;
    final finished = <_Flight>[];
    for (final flight in layer.flights) {
      flight.startedAt ??= elapsed;
      final total = flight.delay + flight.duration;
      if (elapsed - flight.startedAt! >= total) finished.add(flight);
    }
    layer.flights.removeWhere(finished.contains);
    for (final flight in finished) {
      flight.done.complete();
    }
    // Sans vol, le minuteur s'arrête mais la couche reste montée : une chaîne
    // de vols (un vol qui en lance un autre) ne repaie pas le montage à chaque étape.
    if (layer.flights.isEmpty) _ticker.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.layer.view = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = <Widget>[];
    for (final flight in widget.layer.flights) {
      final item = _renderFlight(flight, _now);
      if (item != null) visible.add(item);
    }
    return Stack(clipBehavior: Clip.none, children: visible);
  }
}

/// Position du vol à l'instant [now]. Null tant que la carte n'est pas lancée (sauf [_Flight.hold]).
/// Déplacement par [Transform] : la carte ne relayoute pas à chaque image (#1058).
Widget? _renderFlight(_Flight flight, Duration now) {
  final started = flight.startedAt;
  final total = (flight.delay + flight.duration).inMicroseconds;
  final wait = total == 0 ? 1.0 : flight.delay.inMicroseconds / total;
  final elapsed = started == null ? 0 : (now - started).inMicroseconds;
  final p = total == 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
  // Équivaut à Interval(wait, 1, curve) : la courbe ne démarre qu'après le délai.
  var t = 0.0;
  if (p > wait) {
    final local = (p - wait) / (1 - wait).clamp(1e-9, 1.0);
    t = flight.curve.transform(local);
  }
  // Avant le départ la carte n'est pas lancée : cachée sauf si [hold].
  if (t == 0 && wait > 0 && !flight.hold) return null;

  // Cible relue à chaque image ; on garde la dernière connue si elle disparaît.
  final target = flight.to() ?? flight.lastTo;
  flight.lastTo = target;
  final r = Rect.lerp(flight.from, target, t)!;
  final sx = r.width / flight.from.width;
  final sy = r.height / flight.from.height;

  Widget card = IgnorePointer(
    child: SizedBox(
      width: flight.from.width,
      height: flight.from.height,
      child: flight.child,
    ),
  );
  final occ = flight.occluder?.call();
  if (occ != null) {
    // Coupe la carte sous le bord bas de la zone : elle semble y entrer.
    // Coordonnées locales de la carte, avant mise à l'échelle.
    card = ClipRect(
      clipper: _BelowEdgeClipper((occ.bottom - r.top) / sy),
      child: card,
    );
  }
  final matrix = Matrix4.translationValues(r.left, r.top, 0)..scale(sx, sy);
  return Positioned(
    left: 0,
    top: 0,
    width: flight.from.width,
    height: flight.from.height,
    child: RepaintBoundary(
      child: Transform(
        transform: matrix,
        alignment: Alignment.topLeft,
        child: card,
      ),
    ),
  );
}

/// Garde la partie de la carte située sous [y] (coordonnées locales de la carte).
class _BelowEdgeClipper extends CustomClipper<Rect> {
  const _BelowEdgeClipper(this.y);

  final double y;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-1e4, y, 1e4, 1e4);

  @override
  bool shouldReclip(_BelowEdgeClipper old) => old.y != y;
}
