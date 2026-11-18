import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Petit bouclier du seuil d'ouverture, en bas à droite de la table.
/// Au toucher, le libellé s'affiche quelques secondes au-dessus (#447).
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
    // Le libellé est superposé à gauche du bouclier : il ne change pas la mise en page
    // de la rangée du bas, donc il reste visible au toucher (#447).
    return GestureDetector(
      key: const Key('ramiMinOpeningShield'),
      onTap: _reveal,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _shield(),
          if (_showing)
            Positioned(
              right: 38,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC1F5A96),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF3E3B0),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.label,
                    key: const Key('ramiMinOpeningLabel'),
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 14,
                      color: Color(0xFFFFFFFF),
                      shadows: [
                        Shadow(color: Color(0xAA000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shield() {
    return Container(
      width: 30,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A8FD6), Color(0xFF1F5A96)],
        ),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFF3E3B0), width: 2),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(6),
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${widget.minimum}',
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 15,
          color: Color(0xFFFFFFFF),
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 2)],
        ),
      ),
    );
  }
}
