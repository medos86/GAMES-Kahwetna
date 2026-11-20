import 'package:material_ui/material_ui.dart';

/// Rack de main posé sur le tapis (#643) : bande plus sombre que le tapis,
/// bordure épaisse style BD, sans texture derrière les cartes.
///
/// Les cartes ou briques sont réduites à la largeur disponible (pas de
/// scroll horizontal, cible tactile conservée à 44 pt minimum).
class FeltHandRack extends StatelessWidget {
  const FeltHandRack({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  static const Color rackColor = Color(0xFF0B6B4B);
  static const Color borderColor = Color(0xFF4A2A10);
  static const double borderWidth = 4;
  static const double minTapTarget = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: rackColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
