import 'package:material_ui/material_ui.dart';

/// Halo qui pulse autour de [child] tant que [active] est vrai (ex. pioche quand c'est
/// au joueur de piocher). Inactif, le child est affiché tel quel, sans animation.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.active,
    required this.child,
    this.color = const Color(0xFFFFD858),
    this.radius = 12,
  });

  final bool active;
  final Color color;
  final double radius;
  final Widget child;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final t = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 + 0.65 * t),
                blurRadius: 6 + 14 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
