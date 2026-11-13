import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/services/card_animations.dart';

/// Fait voler [child] de [from] à [to] (repères écran) par-dessus l'écran (#224).
/// Sans effet si le réglage est coupé ou si le système réduit les animations.
Future<void> flyCard({
  required BuildContext context,
  required Rect from,
  required Rect to,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
}) {
  final overlay = Overlay.maybeOf(context);
  final reduced = MediaQuery.disableAnimationsOf(context);
  if (overlay == null || reduced || !cardAnimations.value) {
    return Future<void>.value();
  }
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
