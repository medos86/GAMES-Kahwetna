import 'package:flutter/material.dart';

/// Équivalent de `whileTap` (motion/react) : réduit légèrement le bouton à l'appui.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            onTap == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: onTap == null
            ? null
            : (_) {
                setState(() => _pressed = false);
                onTap();
              },
        onTapCancel:
            onTap == null ? null : () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
