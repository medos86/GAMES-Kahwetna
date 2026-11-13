import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/services/card_animations.dart';

/// Position écran d'un widget identifié par [key], ou null s'il n'est pas affiché (#238).
Rect? rectOfKey(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Fait voler [child] de [from] à [to] (repères écran) par-dessus l'écran (#224).
/// [delay] retarde le départ (distributions échelonnées), sans second minuteur.
/// Sans effet si le réglage est coupé, si le système réduit les animations
/// ou si [from] / [to] est absent.
Future<void> flyCard({
  required BuildContext context,
  required Rect? from,
  required Rect? to,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Duration delay = Duration.zero,
}) {
  if (from == null || to == null) return Future<void>.value();
  if (!cardAnimations.value || MediaQuery.disableAnimationsOf(context)) {
    return Future<void>.value();
  }
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return Future<void>.value();

  final total = delay + duration;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      onEnd: () {
        entry.remove();
        done.complete();
      },
      builder: (context, t, _) {
        // t parcourt delay + duration : la carte attend son tour puis vole.
        final elapsed = t * total.inMicroseconds;
        final local = ((elapsed - delay.inMicroseconds) /
                duration.inMicroseconds)
            .clamp(0.0, 1.0);
        if (local == 0) return const SizedBox.shrink();
        final r = Rect.lerp(from, to, Curves.easeInOut.transform(local))!;
        return Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: IgnorePointer(child: child),
        );
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}
