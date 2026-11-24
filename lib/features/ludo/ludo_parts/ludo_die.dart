part of '../ludo_screen.dart';

/// Taille de la cible tactile du dé (#598, #621) : au-dessus du minimum 48 dp, et
/// égale à la taille du dé affiché, pour que seul le dé lance (#621).
const double kLudoDieTapSize = 52;

/// Dé cliquable du joueur actif : pulse tant qu'il peut lancer (désactivé si
/// l'utilisateur a réduit les animations).
class _RollableDie extends StatefulWidget {
  const _RollableDie({
    required this.pulse,
    required this.onTap,
    required this.child,
    this.wobble = true,
  });

  final bool pulse;
  final VoidCallback? onTap;
  final Widget child;

  /// Faux si le dé affiche déjà le lancer de ce tour (lancer consécutif) : seul
  /// le halo reste, le dé ne bouge pas avant le clic (#857).
  final bool wobble;

  @override
  State<_RollableDie> createState() => _RollableDieState();
}

class _RollableDieState extends State<_RollableDie>
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
  void didUpdateWidget(covariant _RollableDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.pulse && widget.wobble) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final clickable = widget.onTap != null;
    return Semantics(
      button: clickable,
      label: clickable ? t('sRollDice') : t('sDie'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Cible tactile d'au moins 56 dp (issue #598, au-dessus du minimum 48 dp),
        // même si le dé affiché est plus petit.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kLudoDieTapSize,
            minHeight: kLudoDieTapSize,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              // Halo doré pendant le tour du joueur (#378).
              child: PulseGlow(
                active: widget.pulse && !reduce,
                radius: 16,
                child: widget.child,
              ),
              builder: (context, child) {
                final wobbling = widget.pulse && widget.wobble && !reduce;
                // Dé qui grossit et oscille légèrement tant qu'il peut être lancé.
                final scale = wobbling ? 1 + 0.14 * _pulse.value : 1.0;
                final angle = wobbling ? (_pulse.value - 0.5) * 0.12 : 0.0;
                return Transform.rotate(
                  angle: angle,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
