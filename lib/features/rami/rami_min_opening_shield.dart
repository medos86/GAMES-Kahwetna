import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Bouclier affichant le seuil d'ouverture ; au toucher, le libellé s'affiche quelques secondes (#447).
class RamiMinOpeningShield extends StatefulWidget {
  const RamiMinOpeningShield({
    super.key,
    required this.minimum,
    required this.label,
  });

  final int minimum;
  final String label;

  @override
  State<RamiMinOpeningShield> createState() => _RamiMinOpeningShieldState();
}

class _RamiMinOpeningShieldState extends State<RamiMinOpeningShield> {
  Timer? _hide;
  bool _showing = false;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _reveal() {
    _hide?.cancel();
    setState(() => _showing = true);
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('ramiMinOpeningShield'),
      onTap: _reveal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2F6FB3),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(22),
              ),
            ),
            child: Text(
              '${widget.minimum}',
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 22,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          if (_showing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.label,
                key: const Key('ramiMinOpeningLabel'),
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
