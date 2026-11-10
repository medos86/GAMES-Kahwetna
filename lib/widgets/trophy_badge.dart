import 'package:flutter/material.dart';

/// Trophée affichant le score cible, avec un halo pulsé (guide §8).
/// Le halo est désactivé si l'utilisateur a réduit les animations.
class TrophyBadge extends StatefulWidget {
  const TrophyBadge({super.key, required this.target, this.size = 44});

  final int target;
  final double size;

  @override
  State<TrophyBadge> createState() => _TrophyBadgeState();
}

class _TrophyBadgeState extends State<TrophyBadge> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _pulse?.dispose();
      _pulse = null;
    } else if (_pulse == null) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final badge = Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.emoji_events, size: size, color: const Color(0xFFFBBF24)),
        Positioned(
          top: size * 0.22,
          child: Text(
            '${widget.target}',
            style: TextStyle(
              fontSize: size * 0.14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
      ],
    );

    final pulse = _pulse;
    final content = pulse == null
        ? badge
        : AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final t = pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 0.94 + 0.12 * t,
                    child: Container(
                      width: size * 1.3,
                      height: size * 1.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14 + 0.22 * t),
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: badge,
          );

    return Semantics(
      label: 'Partie en ${widget.target} points',
      child: SizedBox(width: size * 1.3, height: size * 1.3, child: Center(child: content)),
    );
  }
}
