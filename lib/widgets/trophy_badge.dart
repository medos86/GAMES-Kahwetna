import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Trophée affichant le score cible, avec un halo pulsé (guide §8).
/// Le halo est désactivé si l'utilisateur a réduit les animations.
class TrophyBadge extends StatefulWidget {
  const TrophyBadge({super.key, required this.target, this.size = 44});

  final int target;
  final double size;

  @override
  State<TrophyBadge> createState() => _TrophyBadgeState();
}

class _TrophyBadgeState extends State<TrophyBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _pulse?.dispose();
      _pulse = null;
    } else {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat(reverse: true);
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
    // Coupe BD (assets/icons/trophy_bd.svg, viewBox 100) : le centre du bol est à y = 34/100.
    // Le score est centré sur ce point, avec un contour d'encre pour rester lisible.
    final scoreStyle = TextStyle(
      fontFamily: 'Bangers',
      fontSize: size * 0.24,
      height: 1,
    );
    final badge = Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/trophy_bd.svg',
          width: size,
          height: size,
          excludeFromSemantics: true,
        ),
        Align(
          alignment: const Alignment(0, -0.32),
          child: SizedBox(
            width: size * 0.6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${widget.target}',
                    style: scoreStyle.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = size * 0.07
                        ..color = const Color(0xFF1B1B1B),
                    ),
                  ),
                  Text(
                    '${widget.target}',
                    style: scoreStyle.copyWith(color: const Color(0xFFFFF7D6)),
                  ),
                ],
              ),
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
      child: SizedBox(
        width: size * 1.3,
        height: size * 1.3,
        child: Center(child: content),
      ),
    );
  }
}
