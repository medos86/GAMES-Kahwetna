part of '../ludo_screen.dart';

/// Dé cliquable du joueur actif : pulse tant qu'il peut lancer (désactivé si
/// l'utilisateur a réduit les animations).
class _RollableDie extends StatefulWidget {
  const _RollableDie({
    required this.pulse,
    required this.onTap,
    required this.child,
  });

  final bool pulse;
  final VoidCallback? onTap;
  final Widget child;

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
    if (widget.pulse) {
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
        // Cible tactile d'au moins 44 px (issue #23), même si le dé affiché est plus petit.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              child: widget.child,
              builder: (context, child) {
                final scale =
                    (widget.pulse && !reduce) ? 1 + 0.08 * _pulse.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
            ),
          ),
        ),
      ),
    );
  }
}
