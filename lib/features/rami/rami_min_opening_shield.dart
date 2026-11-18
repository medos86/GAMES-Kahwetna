import 'package:material_ui/material_ui.dart';

/// Petit bouclier du seuil d'ouverture, placé en haut à droite du tapis (#522).
/// Passif : aucun événement de clic, le seuil reste lisible en permanence.
class RamiMinOpeningShield extends StatelessWidget {
  const RamiMinOpeningShield({
    super.key,
    required this.minimum,
    required this.label,
  });

  final int minimum;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('ramiMinOpeningShield'),
      label: label,
      excludeSemantics: true,
      child: Container(
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
          '$minimum',
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 15,
            color: Color(0xFFFFFFFF),
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
