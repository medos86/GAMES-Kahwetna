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
/// [delay] décale le départ (distributions échelonnées).
/// Sans effet si le réglage est coupé, si le système réduit les animations
/// ou si [from] / [to] est absent.
Future<void> flyCard({
  required BuildContext context,
  required Rect? from,
  required Rect? to,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Duration delay = Duration.zero,
}) async {
  if (from == null || to == null) return;
  if (!cardAnimations.value || MediaQuery.disableAnimationsOf(context)) return;
  if (delay > Duration.zero) {
    await Future<void>.delayed(delay);
  }
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeInOut,
      onEnd: () {
        entry.remove();
        done.complete();
      },
      builder: (context, t, _) {
        final r = Rect.lerp(from, to, t)!;
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
