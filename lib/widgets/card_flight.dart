import 'dart:async';

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
Future<void> flyCard({
  required BuildContext context,
  required Rect? from,
  required Rect? Function() to,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Duration delay = Duration.zero,
  bool hold = false,
  Rect? Function()? occluder,
}) {
  final start = to();
  if (from == null || start == null) return Future<void>.value();
  if (!cardAnimations.value || MediaQuery.disableAnimationsOf(context)) {
    return Future<void>.value();
  }
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return Future<void>.value();

  final total = delay + duration;
  // Part du temps d'attente : la courbe reste à 0 pendant le délai.
  final wait = delay.inMicroseconds / total.inMicroseconds;
  final Curve curve = wait == 0
      ? Curves.easeInOutCubic
      : Interval(wait, 1, curve: Curves.easeInOutCubic);
  var lastTo = start;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: curve,
      onEnd: () {
        entry.remove();
        done.complete();
      },
      builder: (context, t, _) {
        // Avant le départ la courbe vaut 0 : la carte n'est pas encore lancée.
        // hold : la carte reste visible à sa place pendant le délai (captures).
        if (t == 0 && wait > 0 && !hold) return const SizedBox.shrink();
        // Cible relue à chaque image ; on garde la dernière connue si elle disparaît.
        final target = to() ?? lastTo;
        lastTo = target;
        final r = Rect.lerp(from, target, t)!;
        final occ = occluder?.call();
        Widget card = IgnorePointer(child: child);
        if (occ != null) {
          // Coupe la carte sous le bord bas de la zone : elle semble y entrer.
          card = ClipRect(
            clipper: _BelowEdgeClipper(occ.bottom - r.top),
            child: card,
          );
        }
        return Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: card,
        );
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
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
