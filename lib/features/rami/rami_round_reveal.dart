import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../widgets/comic/action_burst.dart';

/// Fin de manche (#417) : un éclat BD annonce le gagnant pendant [delay],
/// puis le tableau des scores ([child]) apparaît.
class RamiRoundReveal extends StatefulWidget {
  const RamiRoundReveal({
    super.key,
    required this.burst,
    required this.child,
    this.delay = const Duration(milliseconds: 2500),
  });

  final String burst;
  final Widget child;
  final Duration delay;

  @override
  State<RamiRoundReveal> createState() => _RamiRoundRevealState();
}

class _RamiRoundRevealState extends State<RamiRoundReveal> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) return widget.child;
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: ActionBurst(text: widget.burst, size: 160),
      ),
    );
  }
}
